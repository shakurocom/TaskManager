//
//
//

import TaskManager_Framework
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // TODO: reuse old example
        let test = TaskManager(name: "test", qualityOfService: QualityOfService.userInitiated, maxConcurrentOperationCount: 6)
        test.cancelAll()
        print("\(test)")
    }

}
