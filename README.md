![Shakuro Task Manager](title_image.png)
<br><br>
# Task Manager
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License MIT](https://img.shields.io/badge/license-MIT-green.svg)

Task Manager is a Swift library for managing various background tasks during the process of iOS development. It implements advanced queue logic that takes into account the operation's priority for the more efficient development of iOS apps.

- [Introduction](#Introduction)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](tmdoc/quick_start.md)
- [Adding dependency](tmdoc/dependency.md)
- [Retry handler](tmdoc/retry.md)
- [License](#license)

## Introduction

Task Manager is an element of an app’s core with the help of which asynchronous operations get performed. It builds dependencies between operations and helps design the correct architecture of their app. It simplifies asynchronous programming, so you can focus on more important things. Perform many independent asynchronous operations simultaneously with one completion block. Every operation has it's own completion block

## How it works

![](TaskManager.png)

Using Operation and OperationQueues you can create your own operations, encapsulating a unit of logic. You can specify and read a few additional properties to further encapsulate logic within the operation itself and keep track of its state. You can also specify a completionBlock that runs when an operation completes.

#Shakuro Task Manager Advantages:

1. Used Base operation. You can create your own operations that encapsulate a unit of logic, easily creating and overriding. A task can have a completion block (onComplete():) and pass all calls to the operation wrapper.
2. Operation Dependency. NSOperations are easy when it comes to task dependency management. It resolves dependencies between operations.
3. Added typing. You can request any type you want.
4. The ability to retry asynchronous operations.
5. It's transparent, flexible, and easy.

## Requirements

- iOS 13.0+
- Xcode 11.0+
- Swift 5.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate TaskManager into your Xcode project, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Shakuro.TaskManager'
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
