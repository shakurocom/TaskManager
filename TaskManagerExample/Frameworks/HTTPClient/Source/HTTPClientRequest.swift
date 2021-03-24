//
/// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol HTTPClientRequest: class {

    var task: URLSessionTask? { get }

    func cancel()

}
