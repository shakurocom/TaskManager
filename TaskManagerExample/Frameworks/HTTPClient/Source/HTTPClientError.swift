//
// Copyright (c) 2018-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Alamofire

extension AFError: NetworkErrorConvertible {
    public func networkError() -> NetworkError {
        if let invalidCode = responseCode {
            return NetworkError(value: .invalidHTTPStatusCode(invalidCode), requestURL: url)
        }
        if let underlyingError: NSError = underlyingError as NSError? {
            return NetworkError(value: .generalError(errorDescription: underlyingError.localizedDescription), requestURL: url)
        }
        return NetworkError(value: .generalError(errorDescription: errorDescription ?? ""), requestURL: url)
    }
}

public enum HTTPClientError: Swift.Error {
    case cantSerializeResponseData
    case cantParseSerializedResponse
}
