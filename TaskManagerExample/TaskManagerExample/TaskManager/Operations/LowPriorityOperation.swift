//
//
//

import Foundation
import Shakuro_TaskManager

internal class LowPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("LowPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}
