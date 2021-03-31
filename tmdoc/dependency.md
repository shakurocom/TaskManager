## Adding dependency

A method that adds custom logic for specific operations. Use `type(of:)` or `operationHash` to identify operations in queue.
Default implementation returns input 'newOperation'.

- newOperation: newly-instantiated operation (from `performOperation()`)
- operationsInQueue: operations already in the queue. Not sorted. Can include operations, that were canceled or already in progress.
- returns: This method must return an operation that will **actually** be added to the queue. To enforce the uniqueness of an operation, return operation, that is already in the queue..
- warning: do not add new dependencies to an operation that is already in the queue.

```swift
// Example: 'sign in' operation is unique (at a time only single 'sign in' operation will be performed)

    let result: TaskManager.OperationInQueue
    switch newOperation {
    case let _ as SignInOperation:
        let signInInQueue = operationsInQueue.first(where: { (operation: Operation) -> Bool in
            return operation.operationHash == newOperation.operationHash
        })
        if let actualSignIn = signInInQueue {
            result = signInInQueue
        } else {
            result = newOperation
        }
        default:
            result = newOperation
        }
        return result
```

```swift
class ExampleTaskManager: TaskManager {

    private let randomOrgClient: HTTPClient

    init(name aName: String, qualityOfService: QualityOfService, maxConcurrentOperationCount: Int, randomOrgClient aRandomOrgClient: HTTPClient) {
        randomOrgClient = aRandomOrgClient
        super.init(name: aName, qualityOfService: qualityOfService, maxConcurrentOperationCount: maxConcurrentOperationCount)
    }

    // Adding dependencings to operations
   
    override func willPerformOperation(newOperation: TaskManager.OperationInQueue,
                                       enqueuedOperations: [TaskManager.OperationInQueue]) -> TaskManager.OperationInQueue {
        let result: TaskManager.OperationInQueue
        switch newOperation {
        case _ as UniqueOperation:
            let uniqueInQueue = enqueuedOperations.first(where: { $0.operationHash == newOperation.operationHash })
            result = uniqueInQueue ?? newOperation

        case _ as DependsOnAlwaysFailOperation:
            let dependencyInQueue = enqueuedOperations.first(where: { $0 is AlwaysFailInTheEndOperation })
            if let actualDependency = dependencyInQueue {
                newOperation.addDependency(operation: actualDependency, isStrongDependency: true)
            }
            result = newOperation

        default:
            result = newOperation
        }
        return result
    }
}
```
