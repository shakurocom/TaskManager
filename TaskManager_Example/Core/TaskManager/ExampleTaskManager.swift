//
//
//

import Foundation
import Shakuro_CommonTypes
import Shakuro_HTTPClient
import TaskManager_Framework

internal class ExampleTaskManager: TaskManager {

    internal let randomOrgClient: HTTPClient

    init(name: String,
         qualityOfService: QualityOfService,
         maxConcurrentOperationCount: Int,
         randomOrgClient: HTTPClient) {
        self.randomOrgClient = randomOrgClient
        super.init(name: name,
                   qualityOfService: qualityOfService,
                   maxConcurrentOperationCount: maxConcurrentOperationCount)
    }

    override func willPerformOperation(newOperation: TaskManager.OperationInQueue,
                                       enqueuedOperations: [TaskManager.OperationInQueue]) -> TaskManager.OperationInQueue {
        let result: TaskManager.OperationInQueue
        switch newOperation {
        case _ as UniqueOperation:
            let operationInQueue = operation(operations: enqueuedOperations, hash: newOperation.operationHash)
            result = operationInQueue ?? newOperation

        case _ as DependsOnAlwaysFailOperation:
            let operationInQueue = operation(operations: enqueuedOperations, hash: newOperation.operationHash)
            if let existingOperation = operationInQueue {
                result = existingOperation
            } else {
                result = newOperation
                formDependency(newOperation: newOperation,
                               queue: enqueuedOperations,
                               oldOperationType: AlwaysFailInTheEndOperation.self,
                               isStrongDependency: true)
            }

        default:
            result = newOperation
        }
        return result
    }

}

// MARK: - Private

private extension ExampleTaskManager {

    private func operation(operations: [OperationInQueue], hash: String) -> OperationInQueue? {
        let operationInQueue = operations.last(where: { (operation) -> Bool in
            return (operation.operationHash == hash) && !operation.isCancelled
        })
        return operationInQueue
    }

    private func formDependency<T>(newOperation: OperationInQueue, queue: [OperationInQueue], oldOperationType: T.Type, isStrongDependency: Bool) {
        if let operationInQueue = queue.last(where: { $0 is T }) {
            newOperation.addDependency(operation: operationInQueue, isStrongDependency: isStrongDependency)
        }
    }

}
