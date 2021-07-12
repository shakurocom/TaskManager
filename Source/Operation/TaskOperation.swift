//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

public protocol AsyncCompletionProtocol: AnyObject {

    /**
     Unique identifier of operation. Consists of `type(of: self)` + `options.optionsHash()`.
     Used in `TaskManager.willPerformOperation()` to resolve operations dependencies.
     See BaseOperationOptions for additional info.
     */
    var operationHash: String { get }

    /**
     Add completion for this operation. You can add several completion blocks (potentially on different queues).
     - parameter queue: queue for a completion block. If `nil` `DispatchQueue.global()` will be used.
     - parameter closure: completion block.
     */
    func onComplete(queue: DispatchQueue?, closure: @escaping () -> Void)

}

/**
 Superclass for `BaseOperation<_,_>`. Used internally. Please do not subclass this directly - use `BaseOperation<_,_>`.
 */
open class TaskOperation<ResultType>: Operation, AsyncCompletionProtocol {

    public var operationHash: String {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    public var operationResult: CancellableAsyncResult<ResultType>? {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

    public func onComplete(queue: DispatchQueue?, closure: @escaping () -> Void) {
        onComplete(queue: queue, closure: { (_) in
            closure()
        })
    }

    /**
     Add completion for this operation. You can add several completion blocks (potentially on different queues).
     - parameter queue: queue for a completion block. If `nil` `DispatchQueue.global()` will be used.
     - parameter closure: completion block.
     */
    func onComplete(queue: DispatchQueue?, closure: @escaping (_ result: CancellableAsyncResult<ResultType>) -> Void) {
        fatalError("Do not subclass TaskOperation - use 'BaseOperation' instead.")
    }

}
