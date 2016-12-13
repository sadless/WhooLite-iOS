//
//  FrequentlyInputViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 3..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class FrequentlyInputViewController: WhooLiteTabBarItemBaseViewController {
    var frequentItem: FrequentItem?
    var mergeArguments: [String: String]?
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "detail", "send":
                let viewController = segue.destination as! FrequentlyInputDetailViewController
                
                viewController.frequentItem = frequentItem
                if identifier == "send" {
                    viewController.mode = .complete
                    viewController.delegate = (embeddedViewController as! FrequentlyInputTableViewController)
                }
            case "merge":
                let viewController = segue.destination as! HistoryTableViewController
                
                viewController.mergeArguments = mergeArguments
            default:
                super.prepare(for: segue, sender: sender)
            }
        }
    }
}
