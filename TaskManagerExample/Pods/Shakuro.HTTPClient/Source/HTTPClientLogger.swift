//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation

public protocol HTTPClientLogger {

    /// Request was formed with provided options and headers.
    /// Called before adding validator/serializers to said request and starting it.
    func clientDidCreateRequest<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                              resolvedHeaders: Alamofire.HTTPHeaders)

    /// Called before parser is applied to response.
    func clientDidReceiveResponse<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                request: URLRequest?,
                                                                response: HTTPURLResponse?,
                                                                responseData: Data?,
                                                                responseError: Error?)

    /// Request is marked as cancelled. no parsing will be done.
    func requestWasCancelled<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                           request: URLRequest?,
                                                           response: HTTPURLResponse?,
                                                           responseData: Data?)

    /// `parseForError()` returned error.
    func parserDidFindError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                          request: URLRequest?,
                                                          response: HTTPURLResponse?,
                                                          responseData: Data?,
                                                          parsedError: Swift.Error)

    /// Some network error happened, that was not handled by parser directly.
    func clientDidEncounterNetworkError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                      request: URLRequest?,
                                                                      response: HTTPURLResponse?,
                                                                      responseData: Data?,
                                                                      networkError: Swift.Error)

    /// Error during serialization of response data (before parsing)
    func clientDidEncounterSerializationError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                            request: URLRequest?,
                                                                            response: HTTPURLResponse?,
                                                                            responseData: Data?,
                                                                            serializationError: Swift.Error)

    /// Error during parsing of serialized data
    func clientDidEncounterParseError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                    request: URLRequest?,
                                                                    response: HTTPURLResponse?,
                                                                    responseData: Data?,
                                                                    parseError: Swift.Error)

}

open class HTTPClientLoggerNone: HTTPClientLogger {

    public init() {}

    open func clientDidCreateRequest<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                   resolvedHeaders: Alamofire.HTTPHeaders) {}

    open func clientDidReceiveResponse<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                     request: URLRequest?,
                                                                     response: HTTPURLResponse?,
                                                                     responseData: Data?,
                                                                     responseError: Error?) {}

    open func requestWasCancelled<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                request: URLRequest?,
                                                                response: HTTPURLResponse?,
                                                                responseData: Data?) {}

    open func parserDidFindError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                               request: URLRequest?,
                                                               response: HTTPURLResponse?,
                                                               responseData: Data?,
                                                               parsedError: Swift.Error) {}

    open func clientDidEncounterNetworkError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                           request: URLRequest?,
                                                                           response: HTTPURLResponse?,
                                                                           responseData: Data?,
                                                                           networkError: Swift.Error) {}

    open func clientDidEncounterSerializationError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                                 request: URLRequest?,
                                                                                 response: HTTPURLResponse?,
                                                                                 responseData: Data?,
                                                                                 serializationError: Swift.Error) {}

    open func clientDidEncounterParseError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                         request: URLRequest?,
                                                                         response: HTTPURLResponse?,
                                                                         responseData: Data?,
                                                                         parseError: Swift.Error) {}

}

/// Full logger, intended for subclassing to provide actual method to output logs.
open class HTTPClientLoggerFull {

    private let tab: String
    private let parametersToCensor: [String]
    private let censoredValue: String

    /// - parameter tab: value used for indentation in multiline messages.
    ///         Default value is `    ` (4 spaces).
    /// - parameter parametersToCensor: parameters with this names will be substituted with `censoredValue` when being put into log.
    ///         Will be checked among headers, root parameters from body/query and authCredential.
    ///         Default value is `[]`
    /// - parameter censoredValue: value with which censored parameters will be substituted.
    ///         Default value is `xxxxxx`.
    public init(tab: String = "    ",
                parametersToCensor: [String] = [],
                censoredValue: String = "xxxxxx") {
        self.tab = tab
        self.parametersToCensor = parametersToCensor
        self.censoredValue = censoredValue
    }

    open func log(_ message: String) {
        fatalError("abstract")
    }

    private func censorParameters(_ parameters: [String: Any]) -> [String: Any] {
        var censoredParameters = parameters
        for bannedParam in parametersToCensor where censoredParameters[bannedParam] != nil {
            censoredParameters[bannedParam] = censoredValue
        }
        return censoredParameters
    }

    open func generateResponseDataDebugDescription(_ responseData: Data?) -> String? {
        guard let data = responseData, !data.isEmpty else {
            return nil
        }
        let debugDescription: String
        if let responseDataString = String(data: data, encoding: .utf8) {
            debugDescription = responseDataString
        } else {
            debugDescription = "\(data)"
        }
        return debugDescription
    }

}

extension HTTPClientLoggerFull: HTTPClientLogger {

    open func clientDidCreateRequest<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                   resolvedHeaders: HTTPHeaders) {
        var requestDescription = "Request: "
        requestDescription.append("\n\(tab)url: \(requestOptions.endpoint.urlString())")
        requestDescription.append("\n\(tab)timeoutInterval: \(requestOptions.timeoutInterval)")
        requestDescription.append("\n\(tab)method: \(requestOptions.method)")
        requestDescription.append("\n\(tab)allHTTPHeaderFields: \(resolvedHeaders)")
        if var realParameters = requestOptions.parameters {
            switch realParameters {
            case .httpBody(let arrayBrakets, let parameters):
                realParameters = .httpBody(arrayBrakets: arrayBrakets, parameters: censorParameters(parameters))
            case .urlQuery(let arrayBrakets, let parameters):
                realParameters = .urlQuery(arrayBrakets: arrayBrakets, parameters: censorParameters(parameters))
            case .json(let parameters):
                if let typedParameters = parameters as? [String: Any] {
                    realParameters = .json(parameters: censorParameters(typedParameters))
                } else {
                    realParameters = .json(parameters: parameters)
                }
            }
            requestDescription.append("\n\(tab)parameters: \(realParameters)")
        }
        if let authCredentialActual = requestOptions.authCredential {
            let credentialForLog = URLCredential(user: censoredValue,
                                                 password: censoredValue,
                                                 persistence: authCredentialActual.persistence)
            requestDescription.append("\n\(tab)authCredential: \(credentialForLog)")
        }

        log(requestDescription)
    }

    open func clientDidReceiveResponse<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                     request: URLRequest?,
                                                                     response: HTTPURLResponse?,
                                                                     responseData: Data?,
                                                                     responseError: Error?) {
        let codeString: String
        if let statusCode = response?.statusCode {
            codeString = "\(statusCode)"
        } else {
            codeString = "unknown"
        }
        let responseHeaderDescription = response?.allHeaderFields.description ?? "No Response Header"
        let responseDataDescription: String
        if let responseRawData = responseData, !responseRawData.isEmpty,
            let responseDataDescriptionActual = generateResponseDataDebugDescription(responseRawData) {
            responseDataDescription = responseDataDescriptionActual
        } else {
            responseDataDescription = "No Response Data"
        }
        let errorDescription: String
        if let error = responseError {
            errorDescription = "\(error)"
        } else {
            errorDescription = "No Error"
        }

        var responseDescription = "Response:"
        responseDescription.append("\n\(tab)url: \(requestOptions.endpoint.urlString())")
        responseDescription.append("\n\(tab)status code: \(codeString)")
        responseDescription.append("\n\(tab)error: \(errorDescription)")
        responseDescription.append("\n\(tab)headers:\n\(responseHeaderDescription)")
        responseDescription.append("\n\(tab)data:\n\(responseDataDescription)")

        log(responseDescription)
    }

    open func requestWasCancelled<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                request: URLRequest?,
                                                                response: HTTPURLResponse?,
                                                                responseData: Data?) {
        // handled by more generic clientDidReceiveResponse()
    }

    open func parserDidFindError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                               request: URLRequest?,
                                                               response: HTTPURLResponse?,
                                                               responseData: Data?,
                                                               parsedError: Error) {
        // handled by more generic clientDidReceiveResponse()
    }

    open func clientDidEncounterNetworkError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                           request: URLRequest?,
                                                                           response: HTTPURLResponse?,
                                                                           responseData: Data?,
                                                                           networkError: Error) {
        // handled by more generic clientDidReceiveResponse()
    }

    open func clientDidEncounterSerializationError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                                 request: URLRequest?,
                                                                                 response: HTTPURLResponse?,
                                                                                 responseData: Data?,
                                                                                 serializationError: Error) {
        // usually handled by parser itself
    }

    open func clientDidEncounterParseError<ParserType: HTTPClientParser>(requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                         request: URLRequest?,
                                                                         response: HTTPURLResponse?,
                                                                         responseData: Data?,
                                                                         parseError: Error) {
        // usually handled by parser itself
    }

}
