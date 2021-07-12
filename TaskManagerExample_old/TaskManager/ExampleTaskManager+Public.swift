//
//
//

import Foundation
import Shakuro_TaskManager

extension ExampleTaskManager {

    internal func doFirstOperation() -> Task<Int> {
        return performOperation(operationType: FirstOperation.self, options: ExampleOperationOptions())
    }

    internal func doUniqueOperation() -> Task<Int> {
        return performOperation(operationType: UniqueOperation.self, options: ExampleOperationOptions())
    }

    internal func doLowPriorityOperation() -> Task<Int> {
        return performOperation(operationType: LowPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doHighPriorityOperation() -> Task<Int> {
        return performOperation(operationType: HighPriorityOperation.self, options: ExampleOperationOptions())
    }

    internal func doDependsOnAlwaysFailOperation() -> Task<Int> {
        return performOperation(operationType: DependsOnAlwaysFailOperation.self, options: ExampleOperationOptions())
    }

    internal func doAlwaysFailInTheEndOperation(retryHandler: RetryHandler<Int>?) -> Task<Int> {
        let group = OperationGroup(mainOperationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        group.addSecondaryOperation(operationType: AlwaysFailInTheEndOperation.self, options: ExampleOperationOptions())
        return performGroup(group, retryHandler: retryHandler)
    }

    internal func requestTenStringsFromRansomOrg() -> Task<String> {
        let options = GetStringsFromRandomOrgOperationOptions(randomOrgClient: randomOrgClient)
        return performOperation(operationType: GetStringsFromRandomOrgOperation.self, options: options)
    }

    internal func retryAlwaysFailThreeTimes() -> Task<Int> {
        let retryCountMax = 3
        return doAlwaysFailInTheEndOperation(retryHandler: RetryHandler(
            retryCondition: { (retryNumber, taskResult) -> Bool in
                switch taskResult {
                case .success:
                    return false
                case .failure:
                    // process error
                    if retryNumber < retryCountMax {
                        print("retrying...")
                        return true
                    } else {
                        print("retrying no more.")
                        return false
                    }
                }
        },
            willRetry: { print("will retry: attempt: \($0) result: \($1)") },
            didRetry: { print("did retry: attempt: \($0) result: \($1)") })
        )
    }

}
