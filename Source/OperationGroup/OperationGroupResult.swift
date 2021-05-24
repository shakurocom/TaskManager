//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

internal struct OperationGroupResult<ResultType, OptionsType: BaseOperationOptions> {
    internal let mainOperation: BaseOperation<ResultType, OptionsType>
    internal let secondaryOperations: [OperationHashProtocol]
}
