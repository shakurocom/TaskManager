//
// Copyright (c) 2018-2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol HTTPClientParser {

    associatedtype ResultType
    associatedtype ResponseValueType

    /// First step of parsing.
    /// Usually this transforms `Data` into `String` or `JSON`
    /// Should throw error if response data can't be serialized.
    func serializeResponseData(_ responseData: Data?) throws -> ResponseValueType

    /// Emit custom server/API -related error (if needed).
    /// Response parsed for error prior to parsing for result.
    /// If you need serialized data here - call `serializeResponseData(responseData)`
    func parseForError(response: HTTPURLResponse?, responseData: Data?) -> Swift.Error?

    /// Parse for successfull response object.
    /// Should throw
    func parseForResult(_ serializedResponse: ResponseValueType, response: HTTPURLResponse?) throws -> ResultType

}
