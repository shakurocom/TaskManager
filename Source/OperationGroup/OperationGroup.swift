//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public final class OperationGroup<ResultType, OptionsType: BaseOperationOptions> {

    internal let mainOperationPrototype: OperationPrototype<ResultType, OptionsType>
    internal private(set) var secondaryOperationPrototypes: [OperationPrototypeProtocol] = []

    public init(mainOperationType: BaseOperation<ResultType, OptionsType>.Type, options: OptionsType) {
        self.mainOperationPrototype = OperationPrototype(operationType: mainOperationType, options: options)
    }

    public func addSecondaryOperation<ResultType, OptionsType: BaseOperationOptions>(operationType: BaseOperation<ResultType, OptionsType>.Type,
                                                                                     options: OptionsType) {
        let newPrototype = OperationPrototype(operationType: operationType, options: options)
        secondaryOperationPrototypes.append(newPrototype)
    }

}
