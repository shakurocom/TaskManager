//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

public protocol OperationHashProtocol: AnyObject {

    /// Unique identifier of operation. Consists of `type(of: self)` + `options.optionsHash()`.
    /// Used in `TaskManager.willPerformOperation()` to resolve operations dependencies.
    /// See BaseOperationOptions for additional info.
    var operationHash: String { get }

}

/// Type of the priority for operation.
public enum OperationPriorityType {

    /// New operations with same priority value will be added to the end of the queue - forming FIFO list
    case fifo

    /// New operations with same priority value will be added to the front of the queue - forming LIFO list
    case lifo

}

internal protocol InternalOperationProtocol {

    var priorityValue: Int { get }
    var priorityType: OperationPriorityType { get }

    func setInternalCompletion(queue: DispatchQueue, closure: @escaping () -> Void)
    func executeOnCompleteCallbacks()

}

/// Superclass for `BaseOperation<_,_>`. Used internally. Please do not subclass this directly - use `BaseOperation<_,_>`.
open class TaskOperation<ResultType>: Operation, OperationHashProtocol, InternalOperationProtocol {

    private let accessLock: NSRecursiveLock

    internal override init() {
        accessLock = NSRecursiveLock()
        accessLock.name = "\(type(of: self)).accessLock"
        super.init()
    }

    public var operationHash: String {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    public var operationResult: CancellableAsyncResult<ResultType>? {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    /// Priority of the task operation. This value should not change after operation was initialized.
    public var priorityValue: Int {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    /// **see** `OperationPriorityType` for description. This value should not change after operation was initialized.
    public var priorityType: OperationPriorityType {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    public final func performProtected<T>(_ closure: () -> T) -> T {
        return accessLock.execute(closure)
    }

    /// Add completion for this operation. You can add several completion blocks (potentially on different queues).
    /// - parameter queue: queue for a completion block. If `nil` `DispatchQueue.global()` will be used.
    /// - parameter closure: completion block.
    public func onComplete(queue: DispatchQueue?, closure: @escaping (_ result: CancellableAsyncResult<ResultType>) -> Void) {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    /// Special completion, that is used by task manager itself to manage its queue.
    /// - parameter queue: queue for a completion block.
    /// - parameter closure: completion block.
    internal func setInternalCompletion(queue: DispatchQueue, closure: @escaping () -> Void) {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    internal func executeOnCompleteCallbacks() {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

}
