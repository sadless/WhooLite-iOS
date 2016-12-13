//
//  DetailBaseViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 4..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class DetailBaseViewController: WithAdmobViewController, SelectAccountTableViewControllerDelegate {
    var sectionId: String?
    var leftAccountType: String?
    var leftAccountId: String?
    var rightAccountType: String?
    var rightAccountId: String?
    var accounts: Results<Account>?
    var itemTitle: String?
    var money = ""
    var memo = ""
    var numberFormatter = NumberFormatter.init()
    var entryDateFormatter = DateFormatter.init()
    var mergeArguments: [String: String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userDefaults = UserDefaults.standard
        let m = getMoney()
        
        sectionId = userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) as? String
        accounts = try! Realm().objects(Account.self).filter("sectionId == %@", sectionId!)
        if itemTitle == nil {
            itemTitle = getItemTitle()
            numberFormatter.numberStyle = .decimal
            if m >= WhooingKeyValues.epsilon {
                money = (numberFormatter.string(from: NSNumber.init(value: m as Double))?.replacingOccurrences(of: ",", with: ""))!
            }
            leftAccountType = getLeftAccountType()
            leftAccountId = getLeftAccountId()
            rightAccountType = getRightAccountType()
            rightAccountId = getRightAccountId()
        }
        entryDateFormatter.dateFormat = "yyyyMMdd"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "embed":
                embeddedViewController = segue.destination
            case "selectLeft":
                let viewController = segue.destination as! SelectAccountTableViewController
                
                viewController.sectionId = sectionId
                viewController.direction = .left
                viewController.accountType = leftAccountType
                viewController.accountId = leftAccountId
                viewController.delegate = self
            case "selectRight":
                let viewController = segue.destination as! SelectAccountTableViewController
                
                viewController.sectionId = sectionId
                viewController.direction = .right
                viewController.accountType = rightAccountType
                viewController.accountId = rightAccountId
                viewController.delegate = self
            case "merge":
                let viewController = segue.destination as! HistoryTableViewController
                
                viewController.mergeArguments = mergeArguments
            default:
                break
            }
        }
    }

    // MARK: - Instance methods
    
    func leftTitle() -> String {
        if (leftAccountType?.isEmpty)! {
            return NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }
        
        let account = accounts?.filter("accountType == %@ AND accountId == %@", leftAccountType!, leftAccountId!).first
        
        if let a = account {
            var title = a.title
            switch a.accountType {
            case WhooingKeyValues.assets:
                title += "+"
            case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
                title += "-"
            default:
                break
            }
            
            return title
        } else {
            return ""
        }
    }
    
    func rightTitle() -> String {
        if (rightAccountType?.isEmpty)! {
            return NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }
        
        let account = accounts?.filter("accountType == %@ AND accountId == %@", rightAccountType!, rightAccountId!).first
        
        if let a = account {
            var title = a.title
            switch a.accountType {
            case WhooingKeyValues.assets:
                title += "-"
            case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
                title += "+"
            default:
                break
            }
            
            return title
        } else {
            return ""
        }
    }
    
    func configureItemTitleCell(_ cell: TextFieldTableViewCell) -> TextFieldTableViewCell {
        cell.promptLabel.text = NSLocalizedString("아이템", comment: "아이템")
        cell.textField.placeholder = NSLocalizedString("아이템", comment: "아이템")
        cell.textField.text = itemTitle
        cell.textField.keyboardType = .default
        cell.textField.returnKeyType = .next
        
        return cell
    }
    
    func configureMoneyCell(_ cell: TextFieldTableViewCell) -> TextFieldTableViewCell {
        cell.promptLabel.text = NSLocalizedString("금액", comment: "금액")
        cell.textField.placeholder = NSLocalizedString("금액", comment: "금액")
        cell.textField.text = money
        cell.textField.keyboardType = .decimalPad
        cell.textField.returnKeyType = .done
        
        return cell
    }
    
    // MARK: - Abstract methods
    
    func getItemTitle() -> String {
        preconditionFailure()
    }
    
    func getMoney() -> Double {
        preconditionFailure()
    }
    
    func getLeftAccountType() -> String {
        preconditionFailure()
    }
    
    func getLeftAccountId() -> String {
        preconditionFailure()
    }
    
    func getRightAccountType() -> String {
        preconditionFailure()
    }
    
    func getRightAccountId() -> String {
        preconditionFailure()
    }
    
    // MARK: - SelectAccountTableViewControllerDelegate methods
    
    func didSelectAccount(_ direction: SelectAccountTableViewController.Direction, accountType: String, accountId: String) {
        switch direction {
        case .left:
            leftAccountType = accountType
            leftAccountId = accountId
        case .right:
            rightAccountType = accountType
            rightAccountId = accountId
        }
        (embeddedViewController as! UITableViewController).tableView.reloadData()
    }
}
