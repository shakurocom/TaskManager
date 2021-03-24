//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol HTTPClientUserSession {
    func httpHeaders() -> [String: String]
}
