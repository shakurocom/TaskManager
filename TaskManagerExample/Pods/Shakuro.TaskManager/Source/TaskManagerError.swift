//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public enum TaskManagerError: Error {

    /// A failsafe error in case something bad has happened inside queue or operation.
    case internalInconsistencyError

}
