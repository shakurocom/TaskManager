//
//
//

import Foundation
import TaskManager_Framework

internal class HighPriorityOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("HighPriorityOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 100
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}
