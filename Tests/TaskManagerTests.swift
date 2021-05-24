//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

@testable import iOSToolboxExample
import XCTest

private struct TestOperationOptions: BaseOperationOptions {
    let releaseExpectation: XCTestExpectation
}

private class TestOperation: BaseOperation<Int, TestOperationOptions> {

    deinit {
        options.releaseExpectation.fulfill()
    }

    open override func main() {
        Thread.sleep(forTimeInterval: TaskManagerTests.operationLength)
        finish(result: .success(result: 0))
    }

    open override var priorityValue: Int {
        return 0
    }

    open override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}

class TaskManagerTests: XCTestCase {

    internal static let operationLength: TimeInterval = 0.5

    func testSingleOperation() {
        let expectation = XCTestExpectation(description: "expecting operation to be released and deinited.")
        let manager = TaskManager(name: "com.shakuro.iOSToolboxTests.TestTaskManager.\(self.hash)", qualityOfService: QualityOfService.utility, maxConcurrentOperationCount: 1)
        autoreleasepool(invoking: {
            let task = manager.performOperation(operationType: TestOperation.self, options: TestOperationOptions(releaseExpectation: expectation))
            XCTAssertFalse(task.isCancelled)
        })
        wait(for: [expectation], timeout: TaskManagerTests.operationLength * 1000000)
    }

}
