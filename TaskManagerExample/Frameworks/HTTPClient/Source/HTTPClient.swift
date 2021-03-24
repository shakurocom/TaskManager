//
// Copyright (c) 2018-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation
//TODO: parse & serialize methods should throw error instead of returning nil
public enum HTTPClientConstant {
    public static let defaultTimeoutInterval: TimeInterval = 60.0
}

open class HTTPClient {

    public enum RequestMethod: CustomStringConvertible {

        case GET
        case PATCH
        case POST
        case PUT
        case DELETE

        public var description: String {
            return alamofireMethod().rawValue
        }

        internal func alamofireMethod() -> Alamofire.HTTPMethod {
            switch self {
            case .GET: return Alamofire.HTTPMethod.get
            case .PATCH: return Alamofire.HTTPMethod.patch
            case .POST: return Alamofire.HTTPMethod.post
            case .PUT: return Alamofire.HTTPMethod.put
            case .DELETE: return Alamofire.HTTPMethod.delete
            }
        }

    }

    public enum ParameterEncoding: CustomStringConvertible {

        case httpBody // formData; URLEncoding with destination of httpBody
        case urlQuery(arrayBrakets: Bool)
        case json

        public var description: String {
            switch self {
            case .httpBody: return "http body"
            case .json: return "JSON body"
            case .urlQuery(let arrayBrakets): return "URL query " + (arrayBrakets ? "with" : "without") + " brakets"
            }
        }

        internal func alamofireEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .httpBody:
                return Alamofire.URLEncoding(destination: URLEncoding.Destination.httpBody)
            case .urlQuery(let arrayBrakets):
                return Alamofire.URLEncoding(destination: URLEncoding.Destination.queryString,
                                             arrayEncoding: arrayBrakets ? .brackets : .noBrackets,
                                             boolEncoding: URLEncoding.BoolEncoding.numeric)
            case .json:
                return Alamofire.JSONEncoding()
            }
        }

    }

    /**
     Essentially this condensed `SendRequestOptions` (after authorizer and stuff)
     */
    private struct RequestData: URLRequestConvertible {

        internal let urlString: String
        internal let method: HTTPMethod
        internal let headers: HTTPHeaders
        internal let timeoutInterval: TimeInterval
        internal let parameterEncoding: Alamofire.ParameterEncoding
        internal let parameters: Alamofire.Parameters?

        internal func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: urlString, method: method, headers: headers)
            request.timeoutInterval = timeoutInterval
            let encodedURLRequest = try parameterEncoding.encode(request, with: parameters)
            return encodedURLRequest
        }

    }

    public struct RequestOptions<ParserType: HTTPClientParserProtocol> {

        public let method: HTTPClient.RequestMethod
        public let endpoint: HTTPClientAPIEndPoint
        public let parser: ParserType.Type
        public var userSession: HTTPClientUserSession?
        public var parameters: [String: Any]?
        /** Default encoding is HTTPClient.ParameterEncoding.json */
        public var parametersEncoding: HTTPClient.ParameterEncoding?
        /**
         Headers will be applied in this order (overriding previous ones if key is the same):
         default for http method -> HTTPClient.defaultHeaders() -> HTTPClientUserSession.httpHeaders() -> RequestOptions.headers
         */
        public var headers: [String: String] = [:]
        public var authCredential: URLCredential?
        public var timeoutInterval: TimeInterval = HTTPClientConstant.defaultTimeoutInterval

        public init(method aMethod: HTTPClient.RequestMethod,
                    endpoint aEndpoint: HTTPClientAPIEndPoint,
                    parser aParser: ParserType.Type) {
            method = aMethod
            endpoint = aEndpoint
            parser = aParser
        }

    }

    // submodules
    private let manager: Alamofire.SessionManager
    private let callbackQueue: DispatchQueue

    // options
    private let acceptableStatusCodes: [Int]
    private let acceptableContentTypes: [String]
    private let defaultGETHeaders: [String: String]
    private let defaultPOSTHeaders: [String: String]
    private let logger: HTTPClientLogger

    // MARK: - Initialization

    public init(name: String,
                configuration: URLSessionConfiguration? = nil,
                acceptableStatusCodes aAcceptableStatusCodes: [Int] = Array(200..<300),
                acceptableContentTypes aAcceptableContentTypes: [String] = ["application/json"],
                requestContentTypes: [String] = ["application/json"],
                logger alogger: HTTPClientLogger = HTTPClientLoggerNone()) {

        let config: URLSessionConfiguration
        if let realConfig = configuration {
            config = realConfig
        } else {
            config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
        }
        manager = Alamofire.SessionManager(configuration: config)
        callbackQueue = DispatchQueue(label: "\(name).callbackQueue", attributes: DispatchQueue.Attributes.concurrent)

        acceptableStatusCodes = aAcceptableStatusCodes
        acceptableContentTypes = aAcceptableContentTypes
        defaultGETHeaders = [
            "Accept": acceptableContentTypes.joined(separator: ",")
        ]
        defaultPOSTHeaders = [
            "Accept": acceptableContentTypes.joined(separator: ","),
            "Content-Type": requestContentTypes.joined(separator: ",")
        ]
        logger = alogger
    }

    // MARK: - Public

    open func defaultHeaders() -> [String: String] {
        return [:]
    }

    public func cancelAllTasks(_ completion: (() -> Void)? = nil) {
        manager.session.getTasksWithCompletionHandler({ (dataTasks, uploadTasks, downloadTasks) in
            for task in dataTasks {
                task.cancel()
            }
            for task in uploadTasks {
                task.cancel()
            }
            for task in downloadTasks {
                task.cancel()
            }
            if let callback: (() -> Void) = completion {
                callback()
            }
        })
    }

    public func sendRequest<ParserType: HTTPClientParserProtocol>(options: RequestOptions<ParserType>,
                                                                  completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>, _ session: HTTPClientUserSession?) -> Void) -> HTTPClientRequest {
        let requestPrefab = formRequest(options: options)
        var request = manager.request(requestPrefab)
        if let credential = options.authCredential {
            request = request.authenticate(usingCredential: credential)
        }
        let currentLogger = logger
        currentLogger.logRequest(requestOptions: options, resolvedHeaders: requestPrefab.headers)
        request = request.validate(statusCode: acceptableStatusCodes)
            .validate(contentType: acceptableContentTypes)
            .response(queue: callbackQueue, completionHandler: { (response: DefaultDataResponse) in
                currentLogger.logResponse(endpoint: options.endpoint, response: response, parser: options.parser)
                let parsedResult = HTTPClient.applyParser(response: response,
                                                          parser: options.parser,
                                                          requestOptions: options,
                                                          logger: currentLogger)
                completion(parsedResult, options.userSession)
            })
        return request
    }

    public func upload<ParserType: HTTPClientParserProtocol>(data: Data,
                                                             options: RequestOptions<ParserType>,
                                                             completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>, _ session: HTTPClientUserSession?) -> Void) -> HTTPClientRequest {
        let requestPrefab = formRequest(options: options)
        var request = manager.upload(data, with: requestPrefab)
        if let credential = options.authCredential {
            request = request.authenticate(usingCredential: credential)
        }
        let currentLogger = logger
        currentLogger.logRequest(requestOptions: options, resolvedHeaders: requestPrefab.headers)
        request.validate(statusCode: acceptableStatusCodes)
            .validate(contentType: acceptableContentTypes)
            .response(queue: callbackQueue, completionHandler: { (response: DefaultDataResponse) in
                currentLogger.logResponse(endpoint: options.endpoint, response: response, parser: options.parser)
                let parsedResult = HTTPClient.applyParser(response: response,
                                                          parser: options.parser,
                                                          requestOptions: options,
                                                          logger: currentLogger)
                completion(parsedResult, options.userSession)
            })
        return request
    }

    /**
     Uploads multi part form data.
     - parameter multipartFormData: The closure used to append body parts to the `MultipartFormData`.
     - parameter encodingSuccess: The closure called when the `MultipartFormData` encoding is successfully complete.
     */
    public func upload<ParserType: HTTPClientParserProtocol>(multipartFormData: @escaping (MultipartFormData) -> Void,
                                                             options: RequestOptions<ParserType>,
                                                             encodingSuccess: ((HTTPClientRequest) -> Void)?,
                                                             completion: @escaping (_ response: CancellableAsyncResult<ParserType.ResultType>, _ session: HTTPClientUserSession?) -> Void) {
        let requestPrefab = formRequest(options: options)
        let currentAcceptableStatusCodes = acceptableStatusCodes
        let currentAcceptableContentTypes = acceptableContentTypes
        let currentCallbackQueue = callbackQueue
        let currentLogger = logger
        let session = options.userSession

        manager.upload(multipartFormData: multipartFormData, with: requestPrefab) { (encodingResult) in
            switch encodingResult {
            case .success(var request, _, _):
                if let credential = options.authCredential {
                    request = request.authenticate(usingCredential: credential)
                }
                encodingSuccess?(request)
                currentLogger.logRequest(requestOptions: options, resolvedHeaders: requestPrefab.headers)
                request.validate(statusCode: currentAcceptableStatusCodes)
                    .validate(contentType: currentAcceptableContentTypes)
                    .response(queue: currentCallbackQueue, completionHandler: { (response: DefaultDataResponse) in
                        currentLogger.logResponse(endpoint: options.endpoint, response: response, parser: options.parser)
                        let parsedResult = HTTPClient.applyParser(response: response,
                                                                  parser: options.parser,
                                                                  requestOptions: options,
                                                                  logger: currentLogger)
                        completion(parsedResult, session)
                    })
            case .failure(let error):
                completion(.failure(error: error), session)
            }
        }
    }

    // MARK: - Private

    private func formHeaders(method: HTTPClient.RequestMethod,
                             endpoint: HTTPClientAPIEndPoint,
                             userSession: HTTPClientUserSession?,
                             additionalHeaders: [String: String]) -> [String: String] {
        var headers: [String: String]
        switch method {
        case .GET,
             .DELETE:
            headers = defaultGETHeaders
        case .POST,
             .PUT,
             .PATCH:
            headers = defaultPOSTHeaders
        }
        defaultHeaders().forEach({ headers[$0] = $1 })
        userSession?.httpHeaders().forEach({ headers[$0] = $1 })
        additionalHeaders.forEach({ headers[$0] = $1 })
        return headers
    }

    private func formRequest<ParserType: HTTPClientParserProtocol>(options: RequestOptions<ParserType>) -> RequestData {
        let requestHeaders = formHeaders(method: options.method,
                                         endpoint: options.endpoint,
                                         userSession: options.userSession,
                                         additionalHeaders: options.headers)
        return RequestData(urlString: options.endpoint.urlString(),
                           method: options.method.alamofireMethod(),
                           headers: requestHeaders,
                           timeoutInterval: options.timeoutInterval,
                           parameterEncoding: options.parametersEncoding?.alamofireEncoding() ?? Alamofire.JSONEncoding(),
                           parameters: options.parameters)
    }

    private static func applyParser<ParserType: HTTPClientParserProtocol>(response: DefaultDataResponse,
                                                                          parser: ParserType.Type,
                                                                          requestOptions: HTTPClient.RequestOptions<ParserType>,
                                                                          logger: HTTPClientLogger) -> CancellableAsyncResult<ParserType.ResultType> {
        if let nsError = response.error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return .cancelled
        }

        let serializedResponseValue: ParserType.ResponseValueType?
        if let responseRawData = response.data {
            serializedResponseValue = parser.serializeResponseData(responseRawData)
        } else {
            serializedResponseValue = nil
        }

        let parserError = parser.parseError(serializedResponseValue, response: response.response, responseData: response.data)
        if let realParserError = parserError {
            return .failure(error: realParserError)
        }

        if let networkError = response.error {
            return .failure(error: networkError)
        }

        guard let responseValue = serializedResponseValue else {
            logger.logParserError(responseData: response.data, requestOptions: requestOptions)
            return .failure(error: HTTPClientError.cantSerializeResponseData)
        }

        guard let parsedObject = parser.parseObject(responseValue, response: response.response) else {
            logger.logParserError(responseData: response.data, requestOptions: requestOptions)
            return .failure(error: HTTPClientError.cantParseSerializedResponse)
        }

        return.success(result: parsedObject)
    }

}

extension Alamofire.Request: HTTPClientRequest {}
