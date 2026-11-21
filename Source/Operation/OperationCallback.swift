//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
#if SWIFT_PACKAGE
import CommonTypes
#else
import Shakuro_CommonTypes
#endif

/// Wrapper for a block, that can be run on a specified queue.
final internal class OperationCallback<ResultType> {

    internal typealias CallbackType = (_ result: CancellableAsyncResult<ResultType>) -> Void

    private let callbackQueue: DispatchQueue?
    private let callback: CallbackType

    internal init (callbackQueue aCallbackQueue: DispatchQueue?, callback aCallback: @escaping CallbackType) {
        callbackQueue = aCallbackQueue
        callback = aCallback
    }

    internal func performAsync(result: CancellableAsyncResult<ResultType>) {
        let queue = callbackQueue ?? DispatchQueue.global()
        queue.async(execute: {
            self.callback(result)
        })
    }

}
