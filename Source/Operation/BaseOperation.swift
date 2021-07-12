//
// Copyright (c) 2018-2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

open class BaseOperation<ResultType, OptionsType: BaseOperationOptions>: TaskOperation<ResultType>, DependencyProtocol, DependentOperation {

    private indirect enum State { // idle -> executing -> finished : always that way
        case idle
        case executing
        case finished(operationResult: CancellableAsyncResult<ResultType>)
    }

    final public let options: OptionsType

    private var state: State
    private var callbacks: [OperationCallback<ResultType>]
    private var internalCallback: OperationCallback<ResultType>?
    private var strongDependencies: [Operation]
    private let internalOperationHash: String

    // MARK: - Initialization

    public required init(options aOptions: OptionsType) {
        options = aOptions
        state = .idle
        callbacks = []
        internalCallback = nil
        strongDependencies = []
        internalOperationHash = "\(type(of: self))-\(options.optionsHash())"
        super.init()
    }

    // MARK: - Properties

    /// See `Operation.isExecuting` for description.
    final public override var isExecuting: Bool {
        switch state {
        case .idle,
             .finished:
            return false
        case .executing:
            return true
        }
    }

    /// See `Operation.isFinidhed` for description.
    final public override var isFinished: Bool {
        switch state {
        case .idle,
             .executing:
            return false
        case .finished:
            return true
        }
    }

    /// Result of the operation. Returns nil if operation is not yet finished.
    public final override var operationResult: CancellableAsyncResult<ResultType>? {
        let result = performProtected({ () -> CancellableAsyncResult<ResultType>? in
            switch state {
            case .idle,
                 .executing:
                return nil
            case .finished(let operationResult):
                return operationResult
            }
        })
        return result
    }

    /// Unique identyfier of operation, including it's options.
    final public override var operationHash: String {
        return internalOperationHash
    }

    // MARK: - Operation actions

    public final override func cancel() {
        performProtected({ () -> Void in
            if !self.isCancelled {
                super.cancel()
                internalCancel()
            }
        })
    }

    public final override func onComplete(queue: DispatchQueue?, closure: @escaping (_ result: CancellableAsyncResult<ResultType>) -> Void) {
        let newCallback = OperationCallback(callbackQueue: queue ?? DispatchQueue.global(),
                                            callback: closure)
        performProtected({ () -> Void in
            switch state {
            case .idle,
                 .executing:
                callbacks.append(newCallback)
            case .finished(let result):
                newCallback.performAsync(result: result)
            }
        })
    }

    public final override func addDependency(_ operation: Operation) {
        addDependencyInternal(operation: operation, isStrongDependency: false)
    }

    public final func addDependency(operation dependencyOperation: TaskManager.OperationInQueue, isStrongDependency: Bool) {
        guard let test = dependencyOperation as? Operation else {
            return
        }
        addDependencyInternal(operation: test, isStrongDependency: isStrongDependency)
    }

    /// Start operation. You can start operation manually, but only if this operation is not in the queue.
    /// You should not start already executing or finished operation.
    /// In debug configuration this will produce assertion failure.
    /// In release - second start will finish operation with `TaskManagerError.internalInconsistencyError`.
    final public override func start() {
        let startFailure = performProtected({ () -> CancellableAsyncResult<ResultType>? in
            var failureResult: CancellableAsyncResult<ResultType>?
            guard self.isReady else {
                assertionFailure("\(type(of: self)): operation is not ready.")
                return .failure(error: TaskManagerError.internalInconsistencyError)
            }
            guard case State.idle = state else {
                assertionFailure("\(type(of: self)): invalid operation state: \(state)")
                return .failure(error: TaskManagerError.internalInconsistencyError)
            }
            changeState(to: State.executing)

            if isCancelled {
                failureResult = .cancelled
            } else {
                for dependency in strongDependencies {
                    if let dependencyOperation = dependency as? DependencyProtocol,
                        let dependencyResult = dependencyOperation.dependencyResult() {
                        switch dependencyResult {
                        case .success:
                            // do nothing
                            break
                        case .cancelled:
                            failureResult = .cancelled
                        case .failure(let error):
                            failureResult = .failure(error: error)
                        }
                        if failureResult != nil {
                            break
                        }
                    }
                }
            }
            // remove dependencies to free some resources
            let currentDependencies = dependencies
            for dependency in currentDependencies {
                removeDependency(dependency)
            }
            strongDependencies.removeAll()
            return failureResult
        })

        autoreleasepool(invoking: {
            if let actualFailure = startFailure {
                finish(result: actualFailure)
            } else {
                main()
            }
        })
    }

    /// Use this method at the end of 'main()' function to properly finish operation and execute callbacks.
    /// - parameter result: result of the operation. You can retrive it via `operationResult` property.
    final public func finish(result: CancellableAsyncResult<ResultType>) {
        performProtected({ () -> Void in
            switch state {
            case .idle,
                 .finished:
                assertionFailure("\(type(of: self)): can't finish operation in state '\(state)'.")
                return

            case .executing:
                changeState(to: State.finished(operationResult: result))
                internalFinished()
                if let callback = internalCallback {
                    // essentially this means, that we are inside TaskManager
                    callback.performAsync(result: result)
                } else {
                    // this is fallback: when operation executed outside of TaskManager (ex.: direct .start())
                    performCallbacksNoLock(operationResult: result)
                }
            }
        })
    }

    // MARK: - Overridables

    /// Use this method to cancel your internal processes. Default implementation does nothing.
    open func internalCancel() {
        // do nothing
    }

    /// Place your code here.
    /// You MUST override it.
    /// You MUST call `finish(result:)` to properly finish operation.
    open override func main() {
        assertionFailure("\(type(of: self)): you MUST override 'main()' function.")
    }

    /// This function will be called inside 'finish(result:)'. You can override it to perform cleanup.
    open func internalFinished() {
        // do nothing
    }

    /// Priority of operation. Works in conjunction with `priorityType`.
    /// This value should not change after operation object was initialized.
    /// Default value is 0.
    open override var priorityValue: Int {
        return 0
    }

    /// See `OperationPriorityType` for description.
    /// This value should not change after operation was initialized.
    /// Deafult value is `OperationPriorityType.fifo`
    open override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

    // MARK: - Internal

    final internal func dependencyResult() -> CancellableAsyncResult<Void>? {
        let result = performProtected({ () -> CancellableAsyncResult<Void>? in
            switch state {
            case .idle,
                 .executing:
                return nil
            case .finished(let opResult):
                return opResult.removingType()
            }
        })
        return result
    }

    /// Special completion, that is used by task manager itself to manage its queue.
    /// - parameter queue: queue for a completion block.
    /// - parameter closure: completion block.
    internal final override func setInternalCompletion(queue: DispatchQueue, closure: @escaping () -> Void) {
        internalCallback = OperationCallback(callbackQueue: queue, callback: { (_) in
            closure()
        })
    }

    final internal override func executeOnCompleteCallbacks() {
        performProtected({
            switch state {
            case .idle,
                 .executing:
                assertionFailure("BaseOperation: invalid state '\(state)'")
            case .finished(operationResult: let operationResult):
                performCallbacksNoLock(operationResult: operationResult)
            }
        })
    }

    // MARK: - Private

    /// Change state of the operation. Also produces proper 'isExecuting' & 'isFinished' KVO notifications.
    private func changeState(to newState: State) {
        switch state {
        case .idle:
            if case State.executing = newState {
                willChangeValue(forKey: "isExecuting")
                state = newState
                didChangeValue(forKey: "isExecuting")
            } else {
                assertionFailure("BaseOperation: invalid state change from '\(state)' to '\(newState)'")
            }

        case .executing:
            if case State.finished = newState {
                willChangeValue(forKey: "isExecuting")
                willChangeValue(forKey: "isFinished")
                state = newState
                didChangeValue(forKey: "isExecuting")
                didChangeValue(forKey: "isFinished")
            } else {
                assertionFailure("BaseOperation: invalid state change from '\(state)' to '\(newState)'")
            }

        case .finished:
            assertionFailure("BaseOperation: invalid state change from '\(state)' to '\(newState)'")
        }
    }

    private func addDependencyInternal(operation dependencyOperation: Operation, isStrongDependency: Bool) {
        performProtected({ () -> Void in
            guard case .idle = state else {
                assertionFailure("BaseOperation: can't add dependencies for operation in state '\(state)'")
                return
            }
            super.addDependency(dependencyOperation)
            if isStrongDependency {
                strongDependencies.append(dependencyOperation)
            }
        })
    }

    private func performCallbacksNoLock(operationResult: CancellableAsyncResult<ResultType>) {
        for callback in callbacks {
            callback.performAsync(result: operationResult)
        }
        callbacks.removeAll()
    }

}
