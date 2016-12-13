//
//  WhooLiteTabBarItemBaseViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 10. 16..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class WhooLiteTabBarItemBaseViewController: WithAdmobViewController {
    @IBOutlet weak var sectionButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var otherActionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = sectionButton
        navigationItem.rightBarButtonItems = [addButton, selectButton]
        
        let index = tabBarController!.viewControllers!.index(of: navigationController!)!
        let tabBarItemTitle = tabBarController?.tabBar.items![index].title
        
        title = embeddedViewController?.title
        tabBarController?.tabBar.items![index].title = tabBarItemTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Action methods
    
    @IBAction func selectTouched(_ sender: AnyObject) {
        let viewController = embeddedViewController as! WhooLiteTabBarItemBaseTableViewController
        
        if let indexPaths = viewController.tableView.indexPathsForVisibleRows {
            viewController.tableView.reloadRows(at: indexPaths, with: .none)
        }
        viewController.tableView.setEditing(true, animated: true)
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItems = [deleteButton, otherActionButton]
        deleteButton.isEnabled = false
        otherActionButton.isEnabled = false
    }
    
    @IBAction func cancelTouched(_ sender: AnyObject) {
        let viewController = embeddedViewController as! WhooLiteTabBarItemBaseTableViewController
        
        viewController.tableView.setEditing(false, animated: true)
        navigationItem.leftBarButtonItem = sectionButton
        navigationItem.rightBarButtonItems = [addButton, selectButton]
    }
    
    @IBAction func deleteTouched(_ sender: AnyObject) {
        let viewController = embeddedViewController as! WhooLiteTabBarItemBaseTableViewController
        
        viewController.deleteSelectedItems()
    }
    
    @IBAction func otherActionTouched(_ sender: AnyObject) {
        let viewController = embeddedViewController as! WhooLiteTabBarItemBaseTableViewController
        
        viewController.otherActionWithSelectedItems()
    }
}
