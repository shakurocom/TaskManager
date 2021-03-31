//
//
//

import Foundation
import Shakuro_HTTPClient

internal class StringsParser: HTTPClientParser {

    typealias ResultType = String
    typealias ResponseValueType = String

    func serializeResponseData(_ responseData: Data?) throws -> String {
        guard let data = responseData else {
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

    func parseForError(response: HTTPURLResponse?, responseData: Data?) -> Swift.Error? {
        guard let statusCode = response?.statusCode, !((200 ... 299) ~= statusCode) else {
            return nil
        }
        return nil
    }

    func parseForResult(_ serializedResponse: String, response: HTTPURLResponse?) throws -> String {
        return serializedResponse
    }

}
