//
//
//

import Foundation
import Shakuro_HTTPClient
import TaskManager_Framework

internal class GetStringsFromRandomOrgOperation: BaseOperation<String, GetStringsFromRandomOrgOperationOptions> {

    override func main() {

        let parameters = HTTPClient.Parameters.urlQuery(arrayBrakets: false, parameters: [
            "num": "10",
            "len": "10",
            "digits": "on",
            "unique": "on",
            "format": "plain",
            "rnd": "new"
        ])

        let requestOptions = HTTPClient.RequestOptions(endpoint: RandomOrgAPIEndpoint.strings,
                                                       method: .get,
                                                       parser: StringsParser(),
                                                       parameters: parameters,
                                                       headers: [HTTPClient.ContentType.textPlain.acceptHeader()])

        _ = options.randomOrgClient.sendRequest(options: requestOptions, completion: { [weak self] (result) in
            guard let strongSelf = self else {
                return
            }
            guard !strongSelf.isCancelled else {
                strongSelf.finish(result: .cancelled)
                return
            }
            switch result {
            case .success(let networkResult):
                strongSelf.finish(result: .success(result: networkResult))
            case .cancelled:
                strongSelf.finish(result: .cancelled)
            case .failure(let networkError):
                strongSelf.finish(result: .failure(error: networkError))
            }
        })
    }

    internal override var priorityValue: Int {
        return 9001
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}
