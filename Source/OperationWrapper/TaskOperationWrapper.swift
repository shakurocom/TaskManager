//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

/// Simple operation wrapper.
internal class TaskOperationWrapper<ResultType>: OperationWrapper<ResultType> {

    private let mainOperation: TaskOperation<ResultType>
    private let secondaryOperations: [OperationHashProtocol]

    init(mainOperation: TaskOperation<ResultType>, secondaryOperations: [OperationHashProtocol]) {
        self.mainOperation = mainOperation
        self.secondaryOperations = secondaryOperations
    }

    internal override var operationHash: String {
        return mainOperation.operationHash
    }

    internal override var isCancelled: Bool {
        return mainOperation.isCancelled
    }

    internal override func cancel() {
        return mainOperation.cancel()
    }

    internal override func onComplete(queue: DispatchQueue?, closure: @escaping (CancellableAsyncResult<ResultType>) -> Void) {
        mainOperation.onComplete(queue: queue, closure: closure)
    }

}
