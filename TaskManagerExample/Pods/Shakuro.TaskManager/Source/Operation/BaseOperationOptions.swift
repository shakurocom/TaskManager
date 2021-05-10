//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public protocol BaseOperationOptions {

    /// Hash string for all **meaningfull** options of operation.
    /// Used in  'BaseOperation.operationHash()'
    /// Default implementation returns empty string(meaning all hashes are equal).
    func optionsHash() -> String

}

public extension BaseOperationOptions {

    func optionsHash() -> String {
        return ""
    }

}
