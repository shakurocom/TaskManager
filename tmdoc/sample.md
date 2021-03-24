## Initialization, creating  and performing operation:

You can request any type you want. In class FirstOperation in the example, it shows that ResultType should be Int. 

 ```swift
struct ExampleOperationOptions: BaseOperationOptions { }

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

    override var priorityValue: Int {
         return 0
     }

    override var priorityType: OperationPriorityType {
         return OperationPriorityType.fifo
     }
}
 
extension ExampleTaskManager {

     internal func doFirstOperation() -> Task<Int> {
         return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
     }

class ExampleTaskManagerViewController: UIViewController {
    
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

}
```
