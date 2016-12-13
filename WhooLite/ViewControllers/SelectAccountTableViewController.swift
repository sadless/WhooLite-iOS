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
    func didSelectAccount(_ direction: SelectAccountTableViewController.Direction, accountType: String, accountId: String)
}

class SelectAccountTableViewController: UITableViewController {
    enum Direction {
        case left
        case right
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
        case .left:
            title = NSLocalizedString("왼쪽", comment: "왼쪽")
            excludeType = WhooingKeyValues.income
        case .right:
            title = NSLocalizedString("오른쪽", comment: "오른쪽")
            excludeType = WhooingKeyValues.expenses
        }
        accounts = try! Realm().objects(Account.self).filter("sectionId == %@ AND accountType != %@", sectionId!, excludeType).sorted(byProperty: "sortOrder", ascending: true)
        accountsToken = accounts?.addNotificationBlock({changes in
            self.tableView.reloadData()
        })
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.init(Notifications.logout), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
        if accountType != nil {
            for i in 0..<(accounts?.count)! {
                let account = accounts?[i]
                
                if account?.accountType == accountType! && account?.accountId == accountId! {
                    var count = 0
                    var section = 0
                    var row = 0
                    
                    while i >= count + accountTypeCounts[section] {
                        count += accountTypeCounts[section]
                        section += 1
                    }
                    row = i - count
                    
                    tableView.scrollToRow(at: IndexPath.init(row: row, section: section + 1), at: .middle, animated: true)
                }
            }
        }
    }
    
    deinit {
        accountsToken?.stop()
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        accountTypes.removeAll()
        accountTypeCounts.removeAll()
        
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
        
        return accountTypes.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return accountTypeCounts[section - 1]
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if indexPath.section == 0 {
            cell.textLabel!.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
            cell.detailTextLabel!.text = nil
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = .default
            cell.textLabel!.font = UIFont.systemFont(ofSize: 16)
            if (accountType?.isEmpty)! {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            let account = itemAtIndexPath(indexPath)
            
            if account.isGroup {
                cell.textLabel!.text = account.title
                cell.detailTextLabel!.text = nil
                cell.backgroundColor = UIColor.init(red: 0xFF / 255.0, green: 0xEB / 255.0, blue: 0x3B / 255.0, alpha: 1)
                cell.selectionStyle = .none
                cell.textLabel!.font = UIFont.boldSystemFont(ofSize: 16)
                cell.accessoryType = .none
            } else {
                cell.textLabel!.text = addSign(account.title, accountType: account.accountType)
                cell.detailTextLabel!.text = account.memo
                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .default
                cell.textLabel!.font = UIFont.systemFont(ofSize: 16)
                if accountType != nil && account.accountType == accountType! && account.accountId == accountId! {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        cell.layoutIfNeeded()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
                case .left:
                    sectionTitle += "+"
                case .right:
                    sectionTitle += "-"
                }
            case WhooingKeyValues.liabilities:
                sectionTitle = NSLocalizedString("부채", comment: "부채")
                switch direction! {
                case .left:
                    sectionTitle += "-"
                case .right:
                    sectionTitle += "+"
                }
            case WhooingKeyValues.capital:
                sectionTitle = NSLocalizedString("순자산", comment: "순자산")
                switch direction! {
                case .left:
                    sectionTitle += "-"
                case .right:
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
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Account {
        let indexPathSection = indexPath.section - 1
        var count = 0
        
        for i in 0..<indexPathSection {
            count += accountTypeCounts[i]
        }
        
        return accounts![count + indexPath.row]
    }
    
    func addSign(_ text: String, accountType: String) -> String {
        var retVal = text
        
        switch accountType {
        case WhooingKeyValues.assets:
            switch direction! {
            case .left:
                retVal += "+"
            case .right:
                retVal += "-"
            }
        case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
            switch direction! {
            case .left:
                retVal += "-"
            case .right:
                retVal += "+"
            }
        default:
            break
        }
        
        return retVal
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row > 0 && itemAtIndexPath(indexPath).isGroup {
            return 24
        } else {
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate?.didSelectAccount(direction!, accountType: "", accountId: "")
        } else {
            let account = itemAtIndexPath(indexPath)
            
            if account.isGroup {
                return
            }
            delegate?.didSelectAccount(direction!, accountType: account.accountType, accountId: account.accountId)
        }
        let _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Notification handler methods
    
    func logout() {
        accountsToken?.stop()
    }
}
