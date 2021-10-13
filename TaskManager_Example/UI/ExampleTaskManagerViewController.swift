//
//
//

import Shakuro_HTTPClient
import UIKit

internal class ExampleTaskManagerViewController: UIViewController {

    @IBOutlet private var operationButton1: UIButton!
    @IBOutlet private var operationButton2: UIButton!
    @IBOutlet private var operationButton3: UIButton!
    @IBOutlet private var operationButton4: UIButton!
    @IBOutlet private var operationButton5: UIButton!
    @IBOutlet private var operationButton6: UIButton!
    @IBOutlet private var operationButton7: UIButton!

    private let taskManager: ExampleTaskManager

    required init?(coder aDecoder: NSCoder) {
        let randomOrgClient = HTTPClient(name: "RandomOrgClient")

        taskManager = ExampleTaskManager(
            name: "com.shakuro.iOSToolboxExample.ExampleTaskManager",
            qualityOfService: QualityOfService.utility,
            maxConcurrentOperationCount: 6,
            randomOrgClient: randomOrgClient)
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        operationButton1.isExclusiveTouch = true
        operationButton1.setTitle("1st operation", for: UIControl.State.normal)
        operationButton2.isExclusiveTouch = true
        operationButton2.setTitle("2nd operation (unique)", for: UIControl.State.normal)
        operationButton3.isExclusiveTouch = true
        operationButton3.setTitle("10 x low + 10 x high priority", for: UIControl.State.normal)
        operationButton4.isExclusiveTouch = true
        operationButton4.setTitle("dependent operation", for: UIControl.State.normal)
        operationButton5.isExclusiveTouch = true
        operationButton5.setTitle("start & cancel 1st", for: UIControl.State.normal)
        operationButton6.isExclusiveTouch = true
        operationButton6.setTitle("get ten strings from random.org", for: UIControl.State.normal)
        operationButton7.isExclusiveTouch = true
        operationButton7.setTitle("retry operation 3 times", for: UIControl.State.normal)
    }

    @IBAction private func operationButton1Tapped() {
        let task = taskManager.doFirstOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton1Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton2Tapped() {
        let task = taskManager.doUniqueOperation()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("operationButton2Tapped() completion. result: \(result)")
        })
    }

    @IBAction private func operationButton3Tapped() {
        for _ in 1...10 {
            _ = taskManager.doLowPriorityOperation()
        }
        for _ in 1...10 {
            _ = taskManager.doHighPriorityOperation()
        }
    }

    @IBAction private func operationButton4Tapped() {
        let task1 = taskManager.doAlwaysFailInTheEndOperation(retryHandler: nil)
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("AlwaysFailInTheEndOperation finished with '\(result)'")
        })
        let task2 = taskManager.doDependsOnAlwaysFailOperation()
        task2.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("DependsOnAlwaysFailOperation finished with '\(result)'")
        })
    }

    @IBAction private func operationButton5Tapped() {
        let task1 = taskManager.doFirstOperation()
        task1.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("first operation completion (should be cancelled): \(result)")
        })
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
            task1.cancel()
            print("operation is now cancelled: \(task1.isCancelled)")
        })
    }

    @IBAction private func operationButton6Tapped() {
        let task = taskManager.requestTenStringsFromRansomOrg()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("data from random.org:\n \(result)")
        })
    }

    @IBAction private func operationButton7Tapped() {
        let task = taskManager.retryAlwaysFailThreeTimes()
        task.onComplete(queue: DispatchQueue.main, closure: { (_, result) in
            print("retry three times finished: \(result)")
        })
    }

}
