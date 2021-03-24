## Quick Start

1. Creating Task Manager (here we will use our HTTPClient):

```swift
class ExampleTaskManager: TaskManager {
    private let randomOrgClient: HTTPClient

    init(name aName: String, qualityOfService: QualityOfService, maxConcurrentOperationCount: Int, randomOrgClient aRandomOrgClient: HTTPClient) {
        randomOrgClient = aRandomOrgClient
        super.init(name: aName, qualityOfService: qualityOfService, maxConcurrentOperationCount: maxConcurrentOperationCount)
    }
    
    internal func doFirstOperation() -> Task<Int> {
        return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
    }
}
```

2. Creating your operation:

```swift
class FirstOperation: BaseOperation<Int, ExampleOperationOptions> {

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
```


3. Running operation from your viewcontroller:

```swift
    internal class ExampleTaskManagerViewController: UIViewController {

        private let taskManager: ExampleTaskManager

        required init?(coder aDecoder: NSCoder) {
            let randomOrgClient = HTTPClient(
                name: "RandomOrgClient",
                acceptableContentTypes: ["text/plain"])
                
            taskManager = ExampleTaskManager(
                name: "com.shakuro.iOSToolboxExample.ExampleTaskManager",
                qualityOfService: QualityOfService.utility,
                maxConcurrentOperationCount: 6,
                randomOrgClient: randomOrgClient)
                
            super.init(coder: aDecoder)
        }

        override func viewDidLoad() {
            super.viewDidLoad()
        }

        @IBAction private func operationButton1Tapped() {
            let task = taskManager.doFirstOperation()
            task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
                print("operationButton1Tapped() completion. result: \(result)")
            })
        }
```
