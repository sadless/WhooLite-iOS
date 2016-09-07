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
        
        var excludeType: String

        switch direction! {
        case .Left:
            title = NSLocalizedString("왼쪽", comment: "왼쪽")
            excludeType = WhooingKeyValues.income
        case .Right:
            title = NSLocalizedString("오른쪽", comment: "오른쪽")
            excludeType = WhooingKeyValues.expenses
        }
        accounts = try! Realm().objects(Account.self).filter("sectionId == %@ AND accountType != %@", sectionId!, excludeType).sorted("sortOrder", ascending: true)
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
        accountTypes.removeAll()
        accountTypeCounts.removeAll()
        
        if accounts?.count > 0 {
            var accountType = accounts![0].accountType
            var count = 0
            
            for account in accounts! {
                if accountType == account.accountType {
                    count += 1
                } else {
                    accountTypes.append(accountType)
                    accountTypeCounts.append(count)
                    accountType = account.accountType
                    count = 1
                }
            }
            accountTypes.append(accountType)
            accountTypeCounts.append(count)
        }
        
        return accountTypes.count + 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            if section == accountTypeCounts.count {
                return accountTypeCounts[section - 1] + 1
            } else {
                return accountTypeCounts[section - 1]
            }
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if indexPath.section == 0 {
            cell.textLabel!.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
            cell.detailTextLabel!.text = nil
        } else if indexPath.section == accountTypes.count && indexPath.row == accountTypeCounts[indexPath.section - 1] {
            cell.textLabel!.text = NSLocalizedString("(알 수 없음)", comment: "알 수 없음")
            cell.detailTextLabel!.text = nil
        } else {
            let account = itemAtIndexPath(indexPath)
            
            cell.textLabel!.text = addSign(account.title, accountType: account.accountType)
            cell.detailTextLabel!.text = account.memo
        }
        cell.layoutIfNeeded()

        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        default:
            let accountType = accountTypes[section - 1]
            var sectionTitle = ""
            
            switch accountType {
            case WhooingKeyValues.assets:
                sectionTitle = NSLocalizedString("자산", comment: "자산")
                switch direction! {
                case .Left:
                    sectionTitle += "+"
                case .Right:
                    sectionTitle += "-"
                }
            case WhooingKeyValues.liabilities:
                sectionTitle = NSLocalizedString("부채", comment: "부채")
                switch direction! {
                case .Left:
                    sectionTitle += "-"
                case .Right:
                    sectionTitle += "+"
                }
            case WhooingKeyValues.capital:
                sectionTitle = NSLocalizedString("순자산", comment: "순자산")
                switch direction! {
                case .Left:
                    sectionTitle += "-"
                case .Right:
                    sectionTitle += "+"
                }
            case WhooingKeyValues.expenses:
                sectionTitle = NSLocalizedString("비용", comment: "비용")
            case WhooingKeyValues.income:
                sectionTitle = NSLocalizedString("수익", comment: "수익")
            default:
                break
            }
            
            return sectionTitle
        }
    }

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

    // MARK: - Instance methods
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> Account {
        let indexPathSection = indexPath.section - 1
        var count = 0
        
        for i in 0..<indexPathSection {
            count += accountTypeCounts[i]
        }
        
        return accounts![count + indexPath.row]
    }
    
    func addSign(text: String, accountType: String) -> String {
        var retVal = text
        
        switch accountType {
        case WhooingKeyValues.assets:
            switch direction! {
            case .Left:
                retVal += "+"
            case .Right:
                retVal += "-"
            }
        case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
            switch direction! {
            case .Left:
                retVal += "-"
            case .Right:
                retVal += "+"
            }
        default:
            break
        }
        
        return retVal
    }
}
