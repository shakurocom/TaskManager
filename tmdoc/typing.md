## Typing

This sample shows how to make, run request and get list of random strings from endpoint:

1. Creating options for our operation:

```swift
internal struct GetStringsFromRandomOrgOperationOptions: BaseOperationOptions {
    let randomOrgClient: HTTPClient
}
```

2. Creating operation:
```swift
internal class GetStringsFromRandomOrgOperation: BaseOperation<String, GetStringsFromRandomOrgOperationOptions> {

    private var request: HTTPClientRequest?

    override func main() {
        var requestOptions = HTTPClient.RequestOptions(
            method: HTTPClient.RequestMethod.GET,
            endpoint: RandomOrgAPIEndpoint.strings,
            parser: StringsParser.self)
            
        requestOptions.parameters = [
            "num": "10",
            "len": "10",
            "digits": "on",
            "unique": "on",
            "format": "plain",
            "rnd": "new"
        ]
        request = options.randomOrgClient.sendRequest(options: requestOptions, completion: { [weak self] (parsedResponse, _) in
            guard let strongSelf = self else {
                return
            }
            switch parsedResponse {
            case .success(let networkResult):
                strongSelf.finish(result: .success(result: networkResult))
            case .cancelled:
                strongSelf.finish(result: .cancelled)
            case .failure(let networkError):
                strongSelf.finish(result: .failure(error: networkError))
            }
        })
    }

    override func internalCancel() {
        request?.cancel()
    }

    internal override var priorityValue: Int {
        return 9001
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
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
            let task = taskManager.requestTenStringsFromRansomOrg()
            task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
                print("data from random.org:\n \(result)")
            })
        }
```

4. Additional settings fot our htttp client (base endpoint, parser, headers etc...)

```swift
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

internal class StringsParser: HTTPClientParserProtocol {

    typealias ResultType = String
    typealias ResponseValueType = String

    static func generateResponseDataDebugDescription(_ responseData: Data) -> String? {
        return serializeResponseData(responseData)
    }

    static func serializeResponseData(_ responseData: Data) -> String? {
        return String(data: responseData, encoding: String.Encoding.utf8)
    }

    static func parseObject(_ object: String, response: HTTPURLResponse?) -> String? {
        return object
    }

    static func parseError(_ object: String?, response: HTTPURLResponse?, responseData: Data?) -> Error? {
        return nil
    }

}

private struct VoidSession: HTTPClientUserSession {

    func httpHeaders() -> [String: String] {
        return [:]
    }

}
```
