//
//
//

import Foundation
import TaskManager_Framework

internal class DependsOnAlwaysFailOperation: BaseOperation<Int, ExampleOperationOptions> {

    override func main() {
        Thread.sleep(forTimeInterval: 1.0)
        print("DependsOnAlwaysFailOperation")
        finish(result: .success(result: priorityValue))
    }

    internal override var priorityValue: Int {
        return 1000
    }

    internal override var priorityType: OperationPriorityType {
        return OperationPriorityType.lifo
    }

}
