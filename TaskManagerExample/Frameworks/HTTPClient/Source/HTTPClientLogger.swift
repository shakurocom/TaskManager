//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation

public protocol HTTPClientLogger {
    func logRequest<ParserType: HTTPClientParserProtocol>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                          resolvedHeaders: [String: String])
    func logResponse<ParserType: HTTPClientParserProtocol>(endpoint: HTTPClientAPIEndPoint,
                                                           response: DefaultDataResponse,
                                                           parser: ParserType.Type)
    func logParserError<ParserType: HTTPClientParserProtocol>(responseData: Data?,
                                                              requestOptions: HTTPClient.RequestOptions<ParserType>)
}

open class HTTPClientLoggerNone: HTTPClientLogger {

    public init() { }

    public func logRequest<ParserType: HTTPClientParserProtocol>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                 resolvedHeaders: [String: String]) {
    }

    public func logResponse<ParserType: HTTPClientParserProtocol>(endpoint: HTTPClientAPIEndPoint,
                                                                  response: DefaultDataResponse,
                                                                  parser: ParserType.Type) {
    }

    public func logParserError<ParserType: HTTPClientParserProtocol>(responseData: Data?,
                                                                     requestOptions: HTTPClient.RequestOptions<ParserType>) {
    }

}
