## Quick Start

1. To create task manager just subclass TaskManager and add http client that will be used in operations to communicate with server:

```swift
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
}

```

2. Creating your operation:

To create your operation just subclass BaseOperation<Int, ExampleOperationOptions>, where Int is type of result and ExampleOperationOptions is an input data for operation.
