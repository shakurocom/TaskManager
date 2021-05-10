//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/// Manager of different background tasks.
/// Implements advanced queue logic that considers operation's priority.
/// To implement some specific logic and operation dependencies you need to override 'resolveLogicFlow()'.
open class TaskManager {

    public typealias OperationInQueue = CancellableOperation & DependentOperation & OperationHashProtocol
    private typealias OperationInQueueInternal = Operation & DependentOperation & OperationHashProtocol & InternalOperationProtocol

    private let name: String
    private let accessLock: NSRecursiveLock
    private let cleanupQueue: DispatchQueue

    private var allOperations: [OperationInQueueInternal]
    private var notEnqueuedOperations: [OperationInQueueInternal] // sorted descending by priority
    private let operationQueue: OperationQueue
    private var isSuspendedInternal: Bool

    private var operationWrappers: [OperationWrapperProtocol] = []

    // MARK: - Initialization

    /// - parameter name: name of the task manager. It will be used as a prefix for instantiated operations.
    /// Example: `com.shakuro.ExampleApp.ExampleTaskManager`
    /// - parameter qualityOfService: QoS for internal queue.
    /// - parameter maxConcurrentOperationCount: maximum number of operations allowed to execute in parallel.
    public init(name aName: String, qualityOfService: QualityOfService, maxConcurrentOperationCount: Int) {
        name = aName
        accessLock = NSRecursiveLock()
        accessLock.name = "\(aName).accessLock"

        allOperations = []
        notEnqueuedOperations = []
        operationQueue = OperationQueue()
        operationQueue.name = "\(aName).workQueue"
        operationQueue.qualityOfService = qualityOfService
        operationQueue.maxConcurrentOperationCount = maxConcurrentOperationCount
        isSuspendedInternal = false
        operationQueue.isSuspended = false
        cleanupQueue = DispatchQueue(label: "\(aName).cleanupQueue", qos: DispatchQoS.utility)
    }

    // MARK: - Public

    /// Convenience version of `performOperation(operations:retryHandler:)` for single operation and no retry block.
    /// You *realy* should handle retry inside operation itself in this case.
    final public func performOperation<ResultType, OptionsType>(operationType: BaseOperation<ResultType, OptionsType>.Type,
                                                                options: OptionsType) -> Task<ResultType> {
        let wrapper = accessLock.execute({ () -> OperationWrapper<ResultType> in
            let group = OperationGroup(mainOperationType: operationType, options: options)
            return performGroupNoLock(group, retryHandler: nil)
        })
        return Task(operationWrapper: wrapper)
    }

    /// Main method of task manager.
    /// It will instantiate operations from group, pass them to `willPerformOperation()` (to resolve dependencies), and then add them to the internal queue.
    /// - parameter group: group of operations to be run. Secondary operation added to the queue before main operation.
    /// - parameter retryHandler: bunch of blocks to handle retry logic.
    /// - returns: opaque token `Task` for created operations. Use it to add completion blocks or cancel underlying operations.
    final public func performGroup<ResultType, OptionsType>(_ group: OperationGroup<ResultType, OptionsType>,
                                                            retryHandler: RetryHandler<ResultType>?) -> Task<ResultType> {
        let wrapper = accessLock.execute({ () -> OperationWrapper<ResultType> in
            return performGroupNoLock(group, retryHandler: retryHandler)
        })
        return Task(operationWrapper: wrapper)
    }

    /// Override this method to add custom logic for specific operations.
    /// Use `type(of:)` or `operationHash` to identify operations in queue.
    ///
    /// Default implementation returns input 'newOperation'.
    ///
    /// - parameter newOperation: newly-instantiated operation (from `performOperation()`)
    /// - parameter operationsInQueue: operations already in queue. Not sorted. Can include operations, that were cancelled or already in progress.
    /// - returns: This method must return operation that will **actually** be added to queue.
    /// To enforce uniqueness of an operation return operation, that is already in queue.
    ///
    /// - warning: do not add new dependencies to operation that is already in queue.
    ///
    /// ```
    /// // Example: 'sign in' operation is unique and will cancel all previous operations:
    ///
    /// let result: TaskManager.OperationInQueue
    /// switch newOperation {
    /// case let _ as SignInOperation:
    ///     let signInInQueue = operationsInQueue.first(where: { (operation: Operation) -> Bool in
    ///         return operation.operationHash == newOperation.operationHash
    ///     })
    ///     if let actualSignIn = signInInQueue {
    ///         result = signInInQueue
    ///     } else {
    ///         result = newOperation
    ///     }
    /// default:
    ///     result = newOperation
    /// }
    /// return result
    /// ```
    open func willPerformOperation(newOperation: TaskManager.OperationInQueue,
                                   enqueuedOperations: [TaskManager.OperationInQueue]) -> TaskManager.OperationInQueue {
        return newOperation
    }

    final public func forEachOperationInQueue(_ closure: (_ operation: OperationInQueue) -> Void) {
        accessLock.execute({
            for operation in allOperations {
                closure(operation)
            }
        })
    }

    /// Cancel all operations.
    final public func cancelAll() {
        accessLock.execute({
            allOperations.forEach({ $0.cancel() })
        })
    }

}

// MARK: - Private

private extension TaskManager {

    /// Instantiate single operation with provided options; resolve retries
    private func performGroupNoLock<ResultType, OptionsType: BaseOperationOptions>(_ group: OperationGroup<ResultType, OptionsType>,
                                                                                   retryHandler: RetryHandler<ResultType>?) -> OperationWrapper<ResultType> {
        let newWrapper: OperationWrapper<ResultType>
        if let realRetryHandler = retryHandler {
            let operations = instantiateOperationGroupNoLock(group)
            newWrapper = RetryTaskOperationWrapper(
                mainOperation: operations.mainOperation,
                secondaryOperations: operations.secondaryOperations,
                retryHandler: { [weak self] (attempt, result) -> RetryBlockResult<ResultType> in
                    guard let strongSelf = self, realRetryHandler.retryCondition(attempt, result) else {
                        return .finish
                    }
                    realRetryHandler.willRetry?(attempt, result)
                    let retriedOperations = strongSelf.accessLock.execute({
                        return strongSelf.instantiateOperationGroupNoLock(group)
                    })
                    realRetryHandler.didRetry?(attempt, result)
                    return .retry(newMainOperation: retriedOperations.mainOperation, newSecondaryOperations: retriedOperations.secondaryOperations)
            })
        } else {
            let operations = instantiateOperationGroupNoLock(group)
            newWrapper = TaskOperationWrapper(mainOperation: operations.mainOperation,
                                              secondaryOperations: operations.secondaryOperations)
        }
        operationWrappers.append(newWrapper)
        newWrapper.onComplete(queue: cleanupQueue, closure: { [weak self] (_) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.accessLock.execute({
                let indexToRemove = strongSelf.operationWrappers.firstIndex(where: { (wrapper) -> Bool in
                    return wrapper === newWrapper
                })
                if let index = indexToRemove {
                    strongSelf.operationWrappers.remove(at: index)
                }
            })
        })
        return newWrapper
    }

    /// Instantiate and add to queue all operations from given `OperationSequence`.
    private func instantiateOperationGroupNoLock<R, O: BaseOperationOptions>(_ group: OperationGroup<R, O>) -> OperationGroupResult<R, O> {
        let secondaryOperations = group.secondaryOperationPrototypes.map({ instantiateOperationNoLock(operation: $0) })
        let mainOperation = instantiateTypedOperationNoLock(operation: group.mainOperationPrototype)
        return OperationGroupResult(mainOperation: mainOperation, secondaryOperations: secondaryOperations)
    }

    /// Typed variant of instantiateOperationNoLock(operation: options:)
    private func instantiateTypedOperationNoLock<R, O: BaseOperationOptions>(operation: OperationPrototype<R, O>) -> BaseOperation<R, O> {
        let newOperation = instantiateOperationNoLock(operation: operation)
        guard let typedResult = newOperation as? BaseOperation<R, O> else {
            fatalError("\(type(of: self)): \(#function): resolved operation has invalid type. " +
                "Expected: \(BaseOperation<R, O>.self). " +
                "Got: \(type(of: newOperation))")
        }
        return typedResult
    }

    /// Instantiate single operation with provided options; resolve dependencies/uniqueness; add new operation to queue.
    private func instantiateOperationNoLock(operation: OperationPrototypeProtocol) -> OperationHashProtocol {
        setSuspendedNoLock(true)

        let newOperation = operation.instantiate()
        guard let typedNewOperation = newOperation as? TaskManager.OperationInQueue else {
            fatalError("\(type(of: self)): \(#function): new operation has invalid type. " +
                "Expected: \(TaskManager.OperationInQueue.self). " +
                "Got: \(type(of: newOperation))")
        }
        let resolvedOperation = willPerformOperation(newOperation: typedNewOperation, enqueuedOperations: allOperations)

        guard let typedResult = resolvedOperation as? OperationInQueueInternal else {
            fatalError("\(type(of: self)): \(#function): resolved operation has invalid type. " +
                "Expected: \(OperationInQueueInternal.self). " +
                "Got: \(type(of: resolvedOperation))")
        }

        if newOperation === typedResult {
            addOperationToQueueNoLock(typedResult)
        }

        setSuspendedNoLock(false)
        return typedResult
    }

}

// MARK: - Queue management

private extension TaskManager {

    /// Add operation to queue. Tries to starts available operations.
    private func addOperationToQueueNoLock(_ newOperation: OperationInQueueInternal) {
        let index: Int?
        switch newOperation.priorityType {
        case .lifo:
            index = notEnqueuedOperations.firstIndex(where: { (oldOperation) -> Bool in
                return oldOperation.priorityValue <= newOperation.priorityValue
            })
        case .fifo:
            index = notEnqueuedOperations.firstIndex(where: { (oldOperation) -> Bool in
                return oldOperation.priorityValue < newOperation.priorityValue
            })
        }
        if let foundIndex = index {
            notEnqueuedOperations.insert(newOperation, at: foundIndex)
        } else {
            notEnqueuedOperations.append(newOperation)
        }
        allOperations.append(newOperation)
        newOperation.setInternalCompletion(queue: cleanupQueue, closure: { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.accessLock.execute({
                let indexToRemove = strongSelf.allOperations.firstIndex(where: { (operation) -> Bool in
                    return operation === newOperation
                })
                if let index = indexToRemove {
                    strongSelf.allOperations.remove(at: index)
                }
                strongSelf.startOperationsNoLock()
            })
            newOperation.executeOnCompleteCallbacks()
        })
        startOperationsNoLock()
    }

    /// Change suspension state of the queue.
    /// Suspended queue can't start additional perations.
    /// Do not affect already started operations.
    private func setSuspendedNoLock(_ newValue: Bool) {
        isSuspendedInternal = newValue
        operationQueue.isSuspended = newValue
        if !isSuspendedInternal {
            startOperationsNoLock()
        }
    }

    /// Start operations from queue if able.
    /// Operation must have all dependencies finished to qualify.
    private func startOperationsNoLock() {
        guard !isSuspendedInternal else {
            return
        }
        while operationQueue.operationCount < operationQueue.maxConcurrentOperationCount {
            let readyOperationIndex = notEnqueuedOperations.firstIndex(where: { (operation) -> Bool in
                return operation.isReady
            })
            if let operationToExecuteIndex = readyOperationIndex {
                let operationToExecute = notEnqueuedOperations[operationToExecuteIndex]
                notEnqueuedOperations.remove(at: operationToExecuteIndex)
                operationQueue.addOperation(operationToExecute)
            } else {
                // no more operations in queue that are ready (with resolved dependencies)
                break
            }
        }
    }

}
