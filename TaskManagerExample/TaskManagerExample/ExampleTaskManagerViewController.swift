//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit
import Shakuro_TaskManager
import Shakuro_HTTPClient
import Shakuro_CommonTypes

private enum MyOperationType: Int {
    case first = 1
    case unique
    case lowPriority
    case highPriority
    case alwaysFailInTheEnd
    case dependsOnAlwaysFail
}

internal class ExampleTaskManager: TaskManager {

    private let randomOrgClient: HTTPClient

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
            formDependency(newOperation: newOperation,
                           queue: enqueuedOperations,
                           oldOperationType: AlwaysFailInTheEndOperation.self,
                           isStrongDependency: true)
            result = newOperation


            // add good example for dependency
//            let operationInQueue = operation(operations: enqueuedOperations, hash: newOperation.operationHash)
//            if let existingOperation = operationInQueue {
//                result = existingOperation
//            } else {
//                result = newOperation
//                formDependency(newOperation: newOperation,
//                               queue: enqueuedOperations,
//                               oldOperationType: AlwaysFailInTheEndOperation.self,
//                               isStrongDependency: false)
//            }

        default:
            result = newOperation
        }
        return result
    }

}

// NOTE: those kind of method usually will go into protocol that is accessible for various view controllers
extension ExampleTaskManager {

    internal func doFirstOperation() -> Task<Int> {
        return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
    }

    internal func doUniqueOperation() -> Task<Int> {
        return performOperation(operationType: UniqueOperation.self, options: ExampleOperationOptions())
    }

    internal func doLowPriorityOperation() -> Task<Int> {
        return performOperation(operationType: LowPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doHighPriorityOperation() -> Task<Int> {
        return performOperation(operationType: HighPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doDependsOnAlwaysFailOperation() -> Task<Int> {
        return performOperation(operationType: DependsOnAlwaysFailOperation.self, options: ExampleOperationOptions())
    }

    internal func doAlwaysFailInTheEndOperation(retryHandler: RetryHandler<Int>?) -> Task<Int> {
        let group = OperationGroup(mainOperationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        return performGroup(group, retryHandler: retryHandler)
    }

    internal func requestTenStringsFromRansomOrg() -> Task<String> {
        let options = GetStringsFromRandomOrgOperationOptions(randomOrgClient: randomOrgClient)
        return performOperation(operationType: GetStringsFromRandomOrgOperation.self, options: options)
    }

    internal func retryAlwaysFailThreeTimes() -> Task<Int> {
        let retryCountMax = 3
        return doAlwaysFailInTheEndOperation(retryHandler: RetryHandler(
            retryCondition: { (retryNumber, taskResult) -> Bool in
                switch taskResult {
                case .success:
                    return false
                case .failure:
                    // process error
                    if retryNumber < retryCountMax {
                        print("retrying...")
                        return true
                    } else {
                        print("retrying no more.")
                        return false
                    }
                }
        },
            willRetry: { print("will retry: attempt: \($0) result: \($1)") },
            didRetry: { print("did retry: attempt: \($0) result: \($1)") })
        )
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

internal struct ExampleOperationOptions: BaseOperationOptions { }

internal class FirstOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 10
        for index in 1...numberOfSteps {
            print("FirstOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
            if isCancelled {
                break
            }
        }
        if isCancelled {
            finish(result: .cancelled)
        } else {
            finish(result: .success(result: numberOfSteps))
        }
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class UniqueOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 15
        for index in 1...15 {
            print("UniqueOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
        }
        finish(result: .success(result: numberOfSteps))
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class LowPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("LowPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class HighPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("HighPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 100
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class AlwaysFailInTheEndOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let stepCount: Int = 10
        for step in 1...stepCount {
            Thread.sleep(forTimeInterval: 0.5)
            print("AlwaysFailsInTheEndOperation: step \(step) / \(stepCount)")
        }
        finish(result: .failure(error: NSError(domain: "ExampleErrorDomain", code: 9001, userInfo: nil)))
    }

    internal override var priorityValue: Int {
        return 1
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

internal class DependsOnAlwaysFailOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("DependsOnAlwaysFailOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 1000
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}

internal struct GetStringsFromRandomOrgOperationOptions: BaseOperationOptions {
    let randomOrgClient: HTTPClient
}

internal class GetStringsFromRandomOrgOperation: BaseOperation<String, GetStringsFromRandomOrgOperationOptions> {

    override func main() {

        let parameters = HTTPClient.Parameters.json(parameters: [
            "num": "10",
            "len": "10",
            "digits": "on",
            "unique": "on",
            "format": "plain",
            "rnd": "new"
        ])

//        let parameters = HTTPClient.Parameters.httpBody(arrayBrakets: false, parameters: [
//            "num": "10",
//            "len": "10",
//            "digits": "on",
//            "unique": "on",
//            "format": "plain",
//            "rnd": "new"
//        ])

//        let parameters = HTTPClient.Parameters.urlQuery(arrayBrakets: false, parameters: [
//            "num": "10",
//            "len": "10",
//            "digits": "on",
//            "unique": "on",
//            "format": "plain",
//            "rnd": "new"
//        ])

        let requestOptions = HTTPClient.RequestOptions(endpoint: RandomOrgAPIEndpoint.strings,
                                                       method: .get,
                                                       parser: StringsParser(),
                                                       parameters: parameters)

        _ = options.randomOrgClient.sendRequest(options: requestOptions, completion: { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            guard !strongSelf.isCancelled else {
                strongSelf.finish(result: .cancelled)
                return
            }
            switch result {
            case .success(let networkResult):
                strongSelf.finish(result: .success(result: networkResult))
            case .cancelled:
                strongSelf.finish(result: .cancelled)
            case .failure(let networkError):
                strongSelf.finish(result: .failure(error: networkError))
            }
        })
    }

    internal override var priorityValue: Int {
        return 9001
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}

internal class ExampleTaskManagerViewController: UIViewController {

    @IBOutlet private var operationButton1: UIButton!
    @IBOutlet private var operationButton2: UIButton!
    @IBOutlet private var operationButton3: UIButton!
    @IBOutlet private var operationButton4: UIButton!
    @IBOutlet private var operationButton5: UIButton!
    @IBOutlet private var operationButton6: UIButton!
    @IBOutlet private var operationButton7: UIButton!

    private let taskManager: ExampleTaskManager

    required init?(coder aDecoder: NSCoder) {
        let randomOrgClient = HTTPClient(name: "RandomOrgClient")

        taskManager = ExampleTaskManager(
            name: "com.shakuro.iOSToolboxExample.ExampleTaskManager",
            qualityOfService: QualityOfService.utility,
            maxConcurrentOperationCount: 6,
            randomOrgClient: randomOrgClient)
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        operationButton1.isExclusiveTouch = true
        operationButton1.setTitle("1st operation", for: UIControl.State.normal)
        operationButton2.isExclusiveTouch = true
        operationButton2.setTitle("2nd operation (unique)", for: UIControl.State.normal)
        operationButton3.isExclusiveTouch = true
        operationButton3.setTitle("10 x low + 10 x high priority", for: UIControl.State.normal)
        operationButton4.isExclusiveTouch = true
        operationButton4.setTitle("dependent operation", for: UIControl.State.normal)
        operationButton5.isExclusiveTouch = true
        operationButton5.setTitle("start & cancel 1st", for: UIControl.State.normal)
        operationButton6.isExclusiveTouch = true
        operationButton6.setTitle("get ten strings from random.org", for: UIControl.State.normal)
        operationButton7.isExclusiveTouch = true
        operationButton7.setTitle("retry operation 3 times", for: UIControl.State.normal)
    }

    @IBAction private func operationButton1Tapped() {
        let task = taskManager.doFirstOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton1Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton2Tapped() {
        let task = taskManager.doUniqueOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton2Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton3Tapped() {
        for _ in 1...10 {
            _ = taskManager.doLowPriorityOperation()
        }
        for _ in 1...10 {
            _ = taskManager.doHighPriorityOperation()
        }
    }

    @IBAction private func operationButton4Tapped() {
        let task1 = taskManager.doAlwaysFailInTheEndOperation(retryHandler: nil)
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("AlwaysFailInTheEndOperation finished with '\(result)'")
        })
        let task2 = taskManager.doDependsOnAlwaysFailOperation()
        task2.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("DependsOnAlwaysFailOperation finished with '\(result)'")
        })
    }

    @IBAction private func operationButton5Tapped() {
        let task1 = taskManager.doFirstOperation()
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("first operation completion (should be cancelled): \(result)")
        })
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
            task1.cancel()
            print("operation is now cancelled: \(task1.isCancelled)")
        })
    }

    @IBAction private func operationButton6Tapped() {
        let task = taskManager.requestTenStringsFromRansomOrg()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("data from random.org:\n \(result)")
        })
    }

    @IBAction private func operationButton7Tapped() {
        let task = taskManager.retryAlwaysFailThreeTimes()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("retry three times finished: \(result)")
        })
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

//import SwiftyJSON
//class AppApiClientParser<T>: HTTPClientParser {
//    typealias ResultType = T
//    typealias ResponseValueType = JSON
//
//    func serializeResponseData(_ responseData: Data?) throws -> JSON {
//        guard let data = responseData else {
//            return JSON()
//        }
//
//        let json = try JSON(data: data)
//        if let message = json["error"]["message"].string {
//            let code = ServerApiErrorCode(rawValue: json["error"]["code"].intValue) ?? .unknown
//            throw ServerApiError.fromResponseData(message, code)
//        }
//        return json
//    }
//
//    func parseForError(response: HTTPURLResponse?, responseData: Data?) -> Swift.Error? {
//        guard let statusCode = response?.statusCode, !((200 ... 299) ~= statusCode) else {
//            return nil
//        }
//        return ServerApiError.fromResponse(ServerApiErrorCode(rawValue: statusCode) ?? .unknown)
//    }
//
//    func parseForResult(_ serializedResponse: JSON, response: HTTPURLResponse?) throws -> T {
//        fatalError()
//    }
//}

internal class StringsParser: HTTPClientParser {

//    typealias ResultType = String
//    typealias ResponseValueType = String
//
//    static func generateResponseDataDebugDescription(_ responseData: Data) -> String? {
//        return serializeResponseData(responseData)
//    }
//
//    static func serializeResponseData(_ responseData: Data) -> String? {
//        return String(data: responseData, encoding: String.Encoding.utf8)
//    }
//
//    static func parseObject(_ object: String, response: HTTPURLResponse?) -> String? {
//        return object
//    }
//
//    static func parseError(_ object: String?, response: HTTPURLResponse?, responseData: Data?) -> Error? {
//        return nil
//    }

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
