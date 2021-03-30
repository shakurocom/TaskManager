//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation

extension HTTPClient {

    /// Sets appropriate value for 'Content-Type' header.
    public enum Parameters: CustomStringConvertible {

        /// formData; URLEncoding with destination of httpBody
        case httpBody(arrayBrakets: Bool, parameters: [String: Any])
        case urlQuery(arrayBrakets: Bool, parameters: [String: Any])
        case json(parameters: Any)

        public var description: String {
            switch self {
            case .httpBody(let arrayBrakets, let parameters):
                return "HTTP body" + (arrayBrakets ? " [braketed]" : "") + " : \(parameters)"
            case .urlQuery(let arrayBrakets, let parameters):
                return "URL query" + (arrayBrakets ? " [braketed]" : "") + " : \(parameters)"
            case .json(let parameters):
                return "JSON body : \(parameters)"
            }
        }

        internal func encode(intoRequest: URLRequest) throws -> URLRequest {
            switch self {
            case .httpBody(let arrayBrakets, let parameters):
                let arrayEncoding: URLEncoding.ArrayEncoding = arrayBrakets ? .brackets : .noBrackets
                let encoding = URLEncoding(destination: .httpBody, arrayEncoding: arrayEncoding)
                return try encoding.encode(intoRequest, with: parameters)
            case .urlQuery(let arrayBrakets, let parameters):
                let arrayEncoding: URLEncoding.ArrayEncoding = arrayBrakets ? .brackets : .noBrackets
                let encoding = URLEncoding(destination: .queryString, arrayEncoding: arrayEncoding)
                return try encoding.encode(intoRequest, with: parameters)
            case .json(let parameters):
                let encoding = JSONEncoding.default
                return try encoding.encode(intoRequest, withJSONObject: parameters)
            }
        }

    }

}
