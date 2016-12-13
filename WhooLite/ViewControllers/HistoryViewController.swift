//
//  HistoryViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 10. 29..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class HistoryViewController: WhooLiteTabBarItemBaseViewController {
    var entry: Entry?
    
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
            case "detail":
                let viewController = segue.destination as! HistoryDetailViewController
                
                viewController.entry = entry
            default:
                super.prepare(for: segue, sender: sender)
            }
        }
    }
}
