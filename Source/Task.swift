//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

public protocol CancellableTask: AnyObject {

    var operationHash: String { get }
    var isCancelled: Bool { get }

    func cancel()

}

/// A 'token' for a paticular task. You are not required to strongly hold this.
public final class Task<ResultType>: CancellableTask {

    private let operationWrapper: OperationWrapper<ResultType>

    internal init(operationWrapper: OperationWrapper<ResultType>) {
        self.operationWrapper = operationWrapper
    }

    /// Identifier of internal operation.
    /// Can be used to detect operation, that was reused from queue.
    public var operationHash: String {
        return operationWrapper.operationHash
    }

    /// `true` if related operation is cancelled.
    public var isCancelled: Bool {
        return operationWrapper.isCancelled
    }

    /// Cancel operation related to this task. You can call this method multiple times.
    public func cancel() {
        operationWrapper.cancel()
    }

    /// Add completion for this task. One task can have several completion blocks attached.
    /// - parameter queue: if `nil` completion will be called on the queue of the backing operation (can be anything).
    /// - parameter closure: completion block. Will be executed asynchroniously on a specified queue.
    public func onComplete(queue: DispatchQueue?,
                           closure: @escaping (_ task: Task<ResultType>, _ result: CancellableAsyncResult<ResultType>) -> Void) {
        operationWrapper.onComplete(queue: queue, closure: { (result: CancellableAsyncResult<ResultType>) in
            closure(self, result)
        })
    }

}
