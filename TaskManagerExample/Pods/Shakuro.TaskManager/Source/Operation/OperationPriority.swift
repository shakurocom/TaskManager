//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

/**
 Type of the priority for operation.
 */
public enum OperationPriorityType {

    /**
     new operations with same priority value will be added to the end of the queue - forming FIFO list
     */
    case fifo

    /**
     new operations with same priority value will be added to the front of the queue - forming LIFO list
     */
    case lifo

}

public protocol PriorityProtocol {

    /**
     Priority of the task operation. This value should not change after operation was initialized.
     */
    var priorityValue: Int { get }

    /**
     - **see** `OperationPriorityType` for description. This value should not change after operation was initialized.
     */
    var priorityType: OperationPriorityType { get }

}
