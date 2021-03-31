//
//
//

import Foundation
import Shakuro_CommonTypes
import Shakuro_HTTPClient
import Shakuro_TaskManager

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















internal enum RandomOrgAPIEndpoint: HTTPClientAPIEndPoint {

    private static let APIBaseURLString = "https://www.random.org"

    case strings

    public func urlString() -> String {
        switch self {
        case .strings:
            return "\(RandomOrgAPIEndpoint.APIBaseURLString)/strings"
        }
    }

}

internal class StringsParser: HTTPClientParser {

    typealias ResultType = String
    typealias ResponseValueType = String

    func serializeResponseData(_ responseData: Data?) throws -> String {
        guard let data = responseData else {
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

    func parseForError(response: HTTPURLResponse?, responseData: Data?) -> Swift.Error? {
        guard let statusCode = response?.statusCode, !((200 ... 299) ~= statusCode) else {
            return nil
        }
        return nil
    }

    func parseForResult(_ serializedResponse: String, response: HTTPURLResponse?) throws -> String {
        return serializedResponse
    }

}
