//
//  FrequentlyInputViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 3..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class FrequentlyInputViewController: WithAdmobViewController {
    var frequentItem: FrequentItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tabBarItemTitle = tabBarController?.tabBar.items![0].title
        
        title = embeddedViewController?.title
        tabBarController?.tabBar.items![0].title = tabBarItemTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "detail":
                let viewController = segue.destinationViewController as! FrequentlyInputDetailViewController
                
                viewController.frequentItem = frequentItem
            case "embed":
                embeddedViewController = segue.destinationViewController
            default:
                break
            }
        }
    }
}
