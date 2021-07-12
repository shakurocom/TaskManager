//
//
//

import Foundation
import Shakuro_HTTPClient

internal enum RandomOrgAPIEndpoint: HTTPClientAPIEndPoint {

    private static let APIBaseURLString = "https://www.random.org"

    case strings

    public func urlString() -> String {
        switch self {
        case .strings:
            return "\(RandomOrgAPIEndpoint.APIBaseURLString)/strings"
        }
    }

}
