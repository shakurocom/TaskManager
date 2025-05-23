![Shakuro Task Manager](Resources/title_image.png)
<br><br>
# Task Manager
![Version](https://img.shields.io/badge/version-1.1.6-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

Task Manager is a Swift library designed to manage asynchronous operations. The main purpose of the Task Manager component is to encapsulate work with the server, database, and other background operations into unit-like operations or tasks. This helps to separate business logic from UI and reuse operations across the app.

![](Resources/task_manager_concept.png)

## Requirements

- iOS 13.0+
- Xcode 15.0+
- Swift 5.0+

## Installation

### CocoaPods

To integrate Task Manager into your Xcode project with CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Shakuro.TaskManager'
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use CocoaPods, you can integrate Shakuro.TaskManager simply by copying it to your project.

## Usage

1. Create a couple of operations by subclassing `BaseOperation`. An operation should be a complete and independent unit of business logic. 
2. Subclass `TaskManager` and override `.willPerformOperation()`. Define dependencies between operations in this method. It’s a good idea to create two separate `TaskManager` objects/subclasses: one to handle auth-related tasks and the second one for all other work.
3. Start your tasks by calling `.performOperation()` or `.performGroup()` on `TaskManager`. You can use completions  to handle results.

Have a look at the [TaskManager_Example](https://github.com/shakurocom/TaskManager/tree/master/TaskManager_Example)

### Important notes

An operation should have `operationHash` defined if its work rely only on its options. Hash is used in `.willPerformOperation()` to construct dependencies.

Carefully consider the dependencies between operations. `.willPerformOperation()` should return an already existing in the queue (old) operation instead of a new one if both operations (old & new) are equal from the business logic perspective. This will result in only single operation being executed with multiple completion callbacks.

Each task (an operation or a group of operations) can have a `retryHandler` to perform a retry under specified conditions. It is a perfect tool if you are dealing with an unreliable server.

Usual flow: Interactor -> Options -> Task Manager (operations + dependencies inside) -> HTTP Client + Database -> Retry if error (for example session expired error) -> Completion block inside Interactor with typed result.

## License

Shakuro.TaskManager is released under the MIT license. [See LICENSE](https://github.com/shakurocom/TaskManager/blob/master/LICENSE.md) for details.

## Give it a try and reach us

Explore our expertise in <a href="https://shakuro.com/services/native-mobile-development/?utm_source=github&utm_medium=repository&utm_campaign=task-manager">Native Mobile Development</a> and <a href="https://shakuro.com/services/ios-dev/?utm_source=github&utm_medium=repository&utm_campaign=task-manager">iOS Development</a>.</p>

If you need professional assistance with your mobile or web project, feel free to <a href="https://shakuro.com/get-in-touch/?utm_source=github&utm_medium=repository&utm_campaign=task-manager">contact our team</a>

