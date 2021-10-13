//
//
//

import Foundation
import TaskManager_Framework

internal class UniqueOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 15
        for index in 1...15 {
            print("UniqueOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
        }
        finish(result: .success(result: numberOfSteps))
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}
