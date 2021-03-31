//
//
//

import Foundation
import Shakuro_TaskManager

internal class FirstOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        let numberOfSteps: Int = 10
        for index in 1...numberOfSteps {
            print("FirstOperation: substep #\(index) / \(numberOfSteps)")
            Thread.sleep(forTimeInterval: 0.5)
            if isCancelled {
                break
            }
        }
        if isCancelled {
            finish(result: .cancelled)
        } else {
            finish(result: .success(result: numberOfSteps))
        }
    }

    internal override var priorityValue: Int {
        return 0
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.fifo
    }

}
