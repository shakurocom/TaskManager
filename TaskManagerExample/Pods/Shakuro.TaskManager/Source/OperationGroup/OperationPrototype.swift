//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

internal protocol OperationPrototypeProtocol {
    func instantiate() -> OperationHashProtocol
}

internal final class OperationPrototype<ResultType, OptionsType: BaseOperationOptions>: OperationPrototypeProtocol {

    private let operationType: BaseOperation<ResultType, OptionsType>.Type
    private let options: OptionsType

    internal init(operationType: BaseOperation<ResultType, OptionsType>.Type, options: OptionsType) {
        self.operationType = operationType
        self.options = options
    }

    internal func instantiate() -> OperationHashProtocol {
        return instantiateTyped()
    }

    internal func instantiateTyped() -> BaseOperation<ResultType, OptionsType> {
        return operationType.init(options: options)
    }

}
