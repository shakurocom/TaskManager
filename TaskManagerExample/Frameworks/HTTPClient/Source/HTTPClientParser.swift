//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol HTTPClientResponseSerializerProtocol {

    associatedtype ResponseValueType

    static func serializeResponseData(_ responseData: Data) -> ResponseValueType?
    static func generateResponseDataDebugDescription(_ responseData: Data) -> String?

}

public protocol HTTPClientParserProtocol: HTTPClientResponseSerializerProtocol {

    associatedtype ResultType

    static func parseObject(_ object: ResponseValueType, response: HTTPURLResponse?) -> ResultType?
    static func parseError(_ object: ResponseValueType?, response: HTTPURLResponse?, responseData: Data?) -> Error?

}
