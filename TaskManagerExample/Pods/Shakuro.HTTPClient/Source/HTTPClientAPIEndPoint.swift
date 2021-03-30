//
// Copyright (c) 2018-2020 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/// This object should describe a "path" part of the URL.
///
/// Example:
///
/// good: `https://www.random.org/strings`
///
/// bad: `https://www.random.org/strings/?num=10&len=10&digits=on&unique=on&format=plain&rnd=new`
public protocol HTTPClientAPIEndPoint {
    func urlString() -> String
}
