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
    var numberFormatter = NSNumberFormatter.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userDefaults = NSUserDefaults.standardUserDefaults()
        let m = getMoney()
        
        sectionId = userDefaults.objectForKey(PreferenceKeys.currentSectionId) as? String
        accounts = try! Realm().objects(Account.self).filter("sectionId == %@", sectionId!)
        itemTitle = getItemTitle()
        numberFormatter.numberStyle = .DecimalStyle
        if m >= WhooingKeyValues.epsilon {
            money = (numberFormatter.stringFromNumber(NSNumber.init(double: m))?.stringByReplacingOccurrencesOfString(",", withString: ""))!
        }
        leftAccountType = getLeftAccountType()
        leftAccountId = getLeftAccountId()
        rightAccountType = getRightAccountType()
        rightAccountId = getRightAccountId()
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
            case "embed":
                embeddedViewController = segue.destinationViewController
            case "selectLeft":
                let viewController = segue.destinationViewController as! SelectAccountTableViewController
                
                viewController.sectionId = sectionId
                viewController.direction = .Left
                viewController.accountType = leftAccountType
                viewController.accountId = leftAccountId
                viewController.delegate = self
            case "selectRight":
                let viewController = segue.destinationViewController as! SelectAccountTableViewController
                
                viewController.sectionId = sectionId
                viewController.direction = .Right
                viewController.accountType = rightAccountType
                viewController.accountId = rightAccountId
                viewController.delegate = self
            default:
                break
            }
        }
    }

    // MARK: - Instance methods
    
    func leftTitle() -> String {
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
            return NSLocalizedString("(알 수 없음)", comment: "(알 수 없음)")
        }
    }
    
    func rightTitle() -> String {
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
            return NSLocalizedString("(알 수 없음)", comment: "(알 수 없음)")
        }
    }
    
    func configureItemTitleCell(cell: TextFieldTableViewCell) -> TextFieldTableViewCell {
        cell.promptLabel.text = NSLocalizedString("아이템", comment: "아이템")
        cell.textField.placeholder = NSLocalizedString("아이템", comment: "아이템")
        cell.textField.text = itemTitle
        cell.textField.returnKeyType = .Next
        
        return cell
    }
    
    func configureMoneyCell(cell: TextFieldTableViewCell) -> TextFieldTableViewCell {
        cell.promptLabel.text = NSLocalizedString("금액", comment: "금액")
        cell.textField.placeholder = NSLocalizedString("금액", comment: "금액")
        cell.textField.text = money
        cell.textField.returnKeyType = .Done
        
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
    
    func didSelectAccount(direction: SelectAccountTableViewController.Direction, accountType: String, accountId: String) {
        switch direction {
        case .Left:
            leftAccountType = accountType
            leftAccountId = accountId
        case .Right:
            rightAccountType = accountType
            rightAccountId = accountId
        }
    }
}
