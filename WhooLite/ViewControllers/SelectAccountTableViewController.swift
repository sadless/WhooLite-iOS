//
//  SelectAccountTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 4..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

protocol SelectAccountTableViewControllerDelegate {
    func didSelectAccount(direction: SelectAccountTableViewController.Direction, accountType: String, accountId: String)
}

class SelectAccountTableViewController: UITableViewController {
    enum Direction {
        case Left
        case Right
    }
    
    var delegate: SelectAccountTableViewControllerDelegate?
    var sectionId: String?
    var accountType: String?
    var accountId: String?
    var direction: Direction?
    var accountTypes = [String]()
    var accountTypeCounts = [Int]()
    var accounts: Results<Account>?
    var accountsToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch direction! {
        case .Left:
            title = NSLocalizedString("왼쪽", comment: "왼쪽")
        case .Right:
            title = NSLocalizedString("오른쪽", comment: "오른쪽")
        }
        accounts = try! Realm().objects(Account.self).filter("sectionId == %@", sectionId!).sorted("sortOrder", ascending: true)
        accountsToken = accounts?.addNotificationBlock({changes in
            switch changes {
            case .Initial:
                break
            default:
                self.tableView.reloadData()
            }
        })
    }
    
    deinit {
        accountsToken?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        for account in accounts! {
            
        }
        
        return accountTypes.count + 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 0
        }
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
