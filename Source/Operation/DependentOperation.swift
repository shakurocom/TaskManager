//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Shakuro_CommonTypes

internal protocol DependencyProtocol: AnyObject {

    /// See `DependencyResult` for description.
    func dependencyResult() -> CancellableAsyncResult<Void>?

}

public protocol DependentOperation {

    /// Add specified operation as a dependency for current operation. Please do not add same operation twice - result is undefined.
    /// - parameter operation: Operation current operation should be dependent upon.
    /// - parameter isStrongDependency: if `true` - failure/cancel of the target operation will be propagated into current operation.
    ///         If operation is strongly dependent on several operations, than firstly encountered failure/cancel will be propagated.
    func addDependency(operation dependencyOperation: TaskManager.OperationInQueue, isStrongDependency: Bool)

}
