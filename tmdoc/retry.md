## Retry handler

RetryHandler - bunch of blocks to handle retry logic. Provides the ability to reattempt a task if error occured.

```swift
 func retryAlwaysFailThreeTimes() -> Task<Int> {
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

func doAlwaysFailInTheEndOperation(retryHandler: RetryHandler<Int>?) -> Task<Int> {
       let group = OperationGroup(mainOperationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
       group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
       group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
       return performGroup(group, retryHandler: retryHandler)
}

// Operation that will allways fail

class AlwaysFailInTheEndOperation: BaseOperation<Int, ExampleOperationOptions> {

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
```
## Callbacks

You can set willRetry and didRetry to get notified before or after the retry handler run. 
