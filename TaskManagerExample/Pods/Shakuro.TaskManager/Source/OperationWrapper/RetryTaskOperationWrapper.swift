//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

/// Enhanced wrapper with ability to retry.
internal final class RetryTaskOperationWrapper<ResultType>: OperationWrapper<ResultType> {

    private enum State {
        case executing
        case finished(result: CancellableAsyncResult<ResultType>)
    }

    private var mainOperation: TaskOperation<ResultType>
    private var secondaryOperations: [OperationHashProtocol]
    private var state: State = .executing
    private let retryHandler: RetryBlock<ResultType>
    private var retryNumber: Int = 0
    private var completions: [OperationCallback<ResultType>] = []
    private let accessLock: NSRecursiveLock

    internal init(mainOperation: TaskOperation<ResultType>,
                  secondaryOperations: [OperationHashProtocol],
                  retryHandler: @escaping RetryBlock<ResultType>) {
        self.mainOperation = mainOperation
        self.secondaryOperations = secondaryOperations
        self.retryHandler = retryHandler
        accessLock = NSRecursiveLock()
        accessLock.name = "\(type(of: self)).accessLock"
        super.init()
        handleOperations()
    }

    internal override var operationHash: String {
        return mainOperation.operationHash
    }

    internal override var isCancelled: Bool {
        return mainOperation.isCancelled
    }

    internal override func cancel() {
        accessLock.execute({
            mainOperation.cancel()
        })
    }

    internal override func onComplete(queue: DispatchQueue?, closure: @escaping (CancellableAsyncResult<ResultType>) -> Void) {
        let newCallback = OperationCallback(callbackQueue: queue, callback: closure)
        accessLock.execute({ () -> Void in
            switch state {
            case .executing:
                completions.append(newCallback)
            case .finished(let result):
                newCallback.performAsync(result: result)
            }
        })
    }

    private func handleOperations() {
        mainOperation.onComplete(queue: nil, closure: { [weak self] (result) -> Void in
            self?.processMainOperationResult(result)
        })
    }

    private func processMainOperationResult(_ mainOperationResult: CancellableAsyncResult<ResultType>) {
        // cancelled operations can't be retried
        if isCancelled {
            accessLock.execute({ () -> Void in
                finishNoLock(result: .cancelled)
            })
            return
        }
        let retryAttemptResult: RetryBlockResult<ResultType>
        switch mainOperationResult {
        case .cancelled:
            accessLock.execute({ () -> Void in
                finishNoLock(result: .cancelled)
            })
            return
        case .success(let result):
            retryAttemptResult = retryHandler(retryNumber, .success(result: result))
        case .failure(let error):
            retryAttemptResult = retryHandler(retryNumber, .failure(error: error))
        }
        accessLock.execute({
            switch retryAttemptResult {
            case .finish:
                finishNoLock(result: mainOperationResult)
            case .retry(let newMainOperation, let newSecondaryOperations):
                retryNumber += 1
                mainOperation = newMainOperation
                secondaryOperations = newSecondaryOperations
                handleOperations()
                // cancel new main operation if we were cancelled somewhere during call to retryHandler block
                if isCancelled {
                    newMainOperation.cancel()
                }
            }
        })
    }

    private func finishNoLock(result: CancellableAsyncResult<ResultType>) {
        // sanity check
        if case .finished = state {
            let log = "invalid state of \(type(of: self)): \(state)"
            assertionFailure(log)
        }
        state = .finished(result: result)
        for callback in completions {
            callback.performAsync(result: result)
        }
        completions.removeAll()
    }

}
