//
// Copyright (c) 2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Alamofire
import Foundation

extension HTTPClient {

    public enum ContentType: String {

        case applicationJavascript = "application/javascript"
        case applicationJSON = "application/json"
        case applicationXWWWFormURLEncoded = "application/x-www-form-urlencoded"
        case applicationXML = "application/xml"
        case applicationZIP = "application/zip"
        case applicationPDF = "application/pdf"
        case applicationSQL = "application/sql"
        case applicationGraphQL = "application/graphql"
        case applicationLDJSON = "application/ld+json"
        case audioMPEG = "audio/mpeg"
        case audioOGG = "audio/ogg"
        case multipartFormData = "multipart/form-data"
        case textCSS = "text/css"
        case textHTML = "text/html"
        case textXML = "text/xml"
        case textCSV = "text/csv"
        case textPlain = "text/plain"
        case imagePNG = "image/png"
        case imageJPEG = "image/jpeg"
        case imageGIF = "image/gif"
        case applicationVNDAPIJSON = "application/vnd.api+json"

        public func acceptHeader() -> Alamofire.HTTPHeader {
            return Alamofire.HTTPHeader.accept(self.rawValue)
        }

        public static func acceptHeader(_ contentTypes: [ContentType]) -> Alamofire.HTTPHeader {
            let value = contentTypes.map({ $0.rawValue }).joined(separator: ",")
            return Alamofire.HTTPHeader.accept(value)
        }

    }

}
