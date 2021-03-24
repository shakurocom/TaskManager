![Shakuro Task Manager](title_image.png)
<br><br>

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

Manager of different background tasks.
Implements advanced queue logic that considers operation's priority.

- [Requirements](#requirements)
- [How it works](tmdoc/index.md)
- [Additional info](#additional-info)
- [Retry handler](tmdoc/retry.md)
- [Installation](#installation)
- [License](#license)

## Introduction

Task Manager is a that simplifies asynchronous programming, so you can focus on the more important things. Perform many independent asynchronous operations simultaneously with one completion block

Using Operation, OperationQueues.
Can create your own operations, encapsulating a unit of logic. You can specify and read a few additional properties to further encapsulate logic within the operation itself and keep track of its state. You can also specify a completionBlock that runs when an operation completes.

Shakuro Task Manager Advantages:

1. Used Base operation. You can create your own operations, that encapsulate a unit of logic, easily creating and overriding. A task can have a completion block (onComplete():) and pass all calls to operation wrapper.
2. Operation Dependency. NSOperations are easy when it comes to task dependency management. It resolves dependencies between operations.
3. Added typing. You can request any type you want.
4. The ability to retry asynchronous operations.
5. It's transparent, flexible and easy.

## Creating Task Manager

1. Pick a readable name
2. Inherit TaskManager
3. Add your additional services if needed.

 ```swift
internal class ExampleTaskManagerViewController: UIViewController {

    private let taskManager: ExampleTaskManager

    init?(coder aDecoder: NSCoder) {
        taskManager = TaskManager(
            name: "com.shakuro.iOSToolboxExample.ExampleTaskManager",
            qualityOfService: QualityOfService.utility,
            maxConcurrentOperationCount: 6)
        super.init(coder: aDecoder)
    }
    
    @IBAction private func operationButton1Tapped() {
        let task = taskManager.doFirstOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton1Tapped() completion. result: \(result)")
        })
    }
    
    func doFirstOperation() -> Task<Int> {
        return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
    }
}

internal class FirstOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        // do your logic
        if isCancelled {
            finish(result: .cancelled)
        } else {
            finish(result: .success(result: 5)) // 5 - because result type Int (BaseOperation<Int, ExampleOperationOptions>)
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

 Main method of task manager `performGroup`
 It instantiates operations from the group, passes them to `willPerformOperation()` (to resolve dependencies), and then add them to the internal queue. (See  [Adding dependency](tmdoc/dependency.md))
 
  ```swift
 func performOperation<ResultType, OptionsType>(operationType: BaseOperation<ResultType, OptionsType>.Type, options: OptionsType) -> Task<ResultType> //or
 func performGroup<ResultType, OptionsType>(_ group: OperationGroup<ResultType, OptionsType>, retryHandler: RetryHandler<ResultType>?) -> Task<ResultType>
  ```
  
## Creating Operation

1. Pick a readable name
2. Inherit BaseOperation
3. Put your logic inside main(), don't forget call inside:
```swift
func finish(result: CancellableAsyncResult<ResultType>) based on the result after starting your async call
```

## Additional info

- [Quick start](tmdoc/quick_start.md)
- [Initialization, creating  and performing operation](tmdoc/sample.md)
- [Adding dependency](tmdoc/dependency.md)

## Requirements

- iOS 13.0+
- Xcode 9.2+
- Swift 5.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Toolbox into your Xcode project, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Shakuro.TaskManager', '0.0.5'
end
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use CocoaPods, you can integrate any/all components from the Shakuro iOS Toolbox simply by copying them to your project.

## License

Shakuro iOS Toolbox is released under the MIT license. [See LICENSE](https://github.com/shakurocom/iOS_Toolbox/blob/master/LICENSE) for details.
