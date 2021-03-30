//
// Copyright (c) 2018-2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Shakuro_CommonTypes
import Foundation

open class HTTPClient {

    // submodules
    private let session: Alamofire.Session
    private let callbackQueue: DispatchQueue
    private let logger: HTTPClientLogger

    // MARK: - Initialization

    public init(name: String,
                configuration: URLSessionConfiguration? = nil,
                logger: HTTPClientLogger = HTTPClientLoggerNone()) {
        let config: URLSessionConfiguration
        if let realConfig = configuration {
            config = realConfig
        } else {
            config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
        }
        self.session = Alamofire.Session(configuration: config)
        self.callbackQueue = DispatchQueue(label: "\(name).callbackQueue", attributes: DispatchQueue.Attributes.concurrent)
        self.logger = logger
    }

    // MARK: - Public

    /// Headers added to all request, performed with this HTTPClient.
    /// Default value is `[]`.
    open func commonHeaders() -> [Alamofire.HTTPHeader] {
        return []
    }

    public func cancelAllTasks(completingOnQueue queue: DispatchQueue = .main, completion: (() -> Void)? = nil) {
        session.cancelAllRequests(completingOnQueue: queue, completion: completion)
    }

    public func sendRequest<ParserType: HTTPClientParser>(
        options: RequestOptions<ParserType>,
        completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>) -> Void)
        -> Alamofire.Request {
            let requestPrefab = formRequest(options: options)
            let request = session.request(requestPrefab)
            let finalizedRequest = finalizeRequest(request,
                                                   options: options,
                                                   resolvedHeaders: requestPrefab.headers,
                                                   acceptableContentTypes: requestPrefab.acceptableContentTypes(),
                                                   completion: completion)
            return finalizedRequest
    }

    public func upload<ParserType: HTTPClientParser>(
        data: Data,
        options: RequestOptions<ParserType>,
        completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>) -> Void)
        -> Alamofire.Request {
            let requestPrefab = formRequest(options: options)
            let request = session.upload(data, with: requestPrefab)
            let finalizedRequest = finalizeRequest(request,
                                                   options: options,
                                                   resolvedHeaders: requestPrefab.headers,
                                                   acceptableContentTypes: requestPrefab.acceptableContentTypes(),
                                                   completion: completion)
            return finalizedRequest
    }

    /// Uploads multi-part form data.
    public func upload<ParserType: HTTPClientParser>(
        multipartFormData: Alamofire.MultipartFormData,
        options: RequestOptions<ParserType>,
        completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>) -> Void)
        -> Alamofire.Request {
            let requestPrefab = formRequest(options: options)
            let request = session.upload(multipartFormData: multipartFormData, with: requestPrefab)
            let finalizedRequest = finalizeRequest(request,
                                                   options: options,
                                                   resolvedHeaders: requestPrefab.headers,
                                                   acceptableContentTypes: requestPrefab.acceptableContentTypes(),
                                                   completion: completion)
            return finalizedRequest
    }

}

// MARK: - Private

private extension HTTPClient {

    /// Condensed version of `RequestOptions`. Parts, that are encoded into URLRequest.
    private struct RequestData: URLRequestConvertible {

        internal let urlString: String
        internal let method: Alamofire.HTTPMethod
        internal let headers: Alamofire.HTTPHeaders
        internal let timeoutInterval: TimeInterval
        internal let parameters: HTTPClient.Parameters?

        internal func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: urlString, method: method, headers: headers)
            request.timeoutInterval = timeoutInterval
            if let realParameters = parameters {
                request = try realParameters.encode(intoRequest: request)
            }
            return request
        }

        internal func acceptableContentTypes() -> [String] {
            guard let acceptHeaderValue = headers.value(for: "Accept") else {
                return ["*/*"]
            }
            return acceptHeaderValue.components(separatedBy: ",")
        }

    }

    private func formRequest<ParserType: HTTPClientParser>(options: RequestOptions<ParserType>) -> RequestData {
        var resolvedHeaders = Alamofire.HTTPHeaders()
        commonHeaders().forEach({ resolvedHeaders.add($0) })
        options.headers.forEach({ resolvedHeaders.add($0) })
        return RequestData(urlString: options.endpoint.urlString(),
                           method: options.method,
                           headers: resolvedHeaders,
                           timeoutInterval: options.timeoutInterval,
                           parameters: options.parameters)
    }

    private func finalizeRequest<ParserType: HTTPClientParser>(
        _ aRequest: Alamofire.DataRequest,
        options: RequestOptions<ParserType>,
        resolvedHeaders: Alamofire.HTTPHeaders,
        acceptableContentTypes: [String],
        completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>) -> Void)
        -> Alamofire.Request {
            var request = aRequest
            if let credential = options.authCredential {
                request = request.authenticate(with: credential)
            }
            let currentLogger = logger
            currentLogger.clientDidCreateRequest(requestOptions: options, resolvedHeaders: resolvedHeaders)
            request = request
                .validate(statusCode: options.acceptableStatusCodes)
                .validate(contentType: acceptableContentTypes)
                .response(queue: callbackQueue, completionHandler: { (response: AFDataResponse<Data?>) in
                    currentLogger.clientDidReceiveResponse(requestOptions: options,
                                                           request: response.request,
                                                           response: response.response,
                                                           responseData: response.data,
                                                           responseError: response.error)
                    let parsedResult = HTTPClient.applyParser(response: response,
                                                              requestOptions: options,
                                                              logger: currentLogger)
                    completion(parsedResult)
                })
            return request
    }

    private static func applyParser<ParserType: HTTPClientParser>(
        response: AFDataResponse<Data?>,
        requestOptions: HTTPClient.RequestOptions<ParserType>,
        logger: HTTPClientLogger) ->
        CancellableAsyncResult<ParserType.ResultType> {
            if let error = response.error, error.isExplicitlyCancelledError {
                logger.requestWasCancelled(requestOptions: requestOptions,
                                           request: response.request,
                                           response: response.response,
                                           responseData: response.data)
                return .cancelled
            }

            // 1) direct parse for error
            if let error = requestOptions.parser.parseForError(response: response.response, responseData: response.data) {
                logger.parserDidFindError(requestOptions: requestOptions,
                                          request: response.request,
                                          response: response.response,
                                          responseData: response.data,
                                          parsedError: error)
                return .failure(error: error)
            }

            // 2) network error
            if let networkError = response.error {
                logger.clientDidEncounterNetworkError(requestOptions: requestOptions,
                                                      request: response.request,
                                                      response: response.response,
                                                      responseData: response.data,
                                                      networkError: networkError)
                return .failure(error: networkError)
            }

            // 3) serialization error
            let serializedResponseValue: ParserType.ResponseValueType
            do {
                serializedResponseValue = try requestOptions.parser.serializeResponseData(response.data)
            } catch let error {
                logger.clientDidEncounterSerializationError(requestOptions: requestOptions,
                                                            request: response.request,
                                                            response: response.response,
                                                            responseData: response.data,
                                                            serializationError: error)
                return .failure(error: HTTPClient.Error.cantSerializeResponseData(underlyingError: error))
            }

            // 4) parsing error
            let parsedObject: ParserType.ResultType
            do {
                parsedObject = try requestOptions.parser.parseForResult(serializedResponseValue, response: response.response)
            } catch let error {
                logger.clientDidEncounterParseError(requestOptions: requestOptions,
                                                    request: response.request,
                                                    response: response.response,
                                                    responseData: response.data,
                                                    parseError: error)
                return .failure(error: HTTPClient.Error.cantParseSerializedResponse(underlyingError: error))
            }

            return .success(result: parsedObject)
    }

}
