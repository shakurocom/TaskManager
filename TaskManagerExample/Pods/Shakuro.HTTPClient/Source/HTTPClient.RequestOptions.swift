//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation

extension HTTPClient {

    public static let defaultTimeoutInterval: TimeInterval = 60.0

    public struct RequestOptions<ParserType: HTTPClientParser> {

        public let endpoint: HTTPClientAPIEndPoint
        public let method: Alamofire.HTTPMethod
        public let parser: ParserType
        public let parameters: Parameters?
        /// Headers will be applied in this order (overriding previous ones if key is the same):
        ///     default for http method -> HTTPClient.commonHeaders() -> RequestOptions.headers
        ///
        /// Default value contains "Accept": "application/json".
        ///
        /// Response will be validated against content type from "Accept" header. For common values see `HTTPClient.Constant`.
        public let headers: [Alamofire.HTTPHeader]
        public let authCredential: URLCredential?
        public let timeoutInterval: TimeInterval
        public let acceptableStatusCodes: Range<Int>

        public init(endpoint: HTTPClientAPIEndPoint,
                    method: Alamofire.HTTPMethod,
                    parser: ParserType,
                    parameters: Parameters? = nil,
                    headers: [Alamofire.HTTPHeader] = [ContentType.applicationJSON.acceptHeader()],
                    authCredential: URLCredential? = nil,
                    timeoutInterval: TimeInterval = defaultTimeoutInterval,
                    acceptableStatusCodes: Range<Int> = 200..<300) {
            self.endpoint = endpoint
            self.method = method
            self.parser = parser
            self.parameters = parameters
            self.headers = headers
            self.authCredential = authCredential
            self.timeoutInterval = timeoutInterval
            self.acceptableStatusCodes = acceptableStatusCodes
        }

    }

}
