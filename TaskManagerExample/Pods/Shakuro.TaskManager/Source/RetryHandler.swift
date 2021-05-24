//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

public final class RetryHandler<ResultType> {

    let retryCondition: (_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Bool
    let willRetry: ((_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Void)?
    let didRetry: ((_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Void)?

    public init(retryCondition: @escaping (_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Bool,
                willRetry: ((_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Void)? = nil,
                didRetry: ((_ attempt: Int, _ previousResult: AsyncResult<ResultType>) -> Void)? = nil) {
        self.retryCondition = retryCondition
        self.willRetry = willRetry
        self.didRetry = didRetry
    }

}

internal enum RetryBlockResult<ResultType> {
    case finish
    case retry(newMainOperation: TaskOperation<ResultType>, newSecondaryOperations: [OperationHashProtocol])
}

internal typealias RetryBlock<ResultType> = (_ retryNumber: Int, _ mainTaskResult: AsyncResult<ResultType>) -> RetryBlockResult<ResultType>
