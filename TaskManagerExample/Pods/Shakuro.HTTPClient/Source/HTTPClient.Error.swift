//
// Copyright (c) 2018-2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Shakuro_CommonTypes
import Foundation

extension AFError: NetworkErrorConvertible {

    public func networkError() -> NetworkError {
        if isResponseValidationError, let invalidCode = responseCode {
            return NetworkError(value: .invalidHTTPStatusCode(invalidCode), requestURL: url)
        }
        if let underlyingError: NSError = underlyingError as NSError? {
            return NetworkError(value: .generalError(errorDescription: underlyingError.localizedDescription), requestURL: url)
        }
        return NetworkError(value: .generalError(errorDescription: errorDescription ?? ""), requestURL: url)
    }

}

extension HTTPClient {

    public enum Error: Swift.Error {
        case cantSerializeResponseData(underlyingError: Swift.Error?)
        case cantParseSerializedResponse(underlyingError: Swift.Error?)
    }

}
