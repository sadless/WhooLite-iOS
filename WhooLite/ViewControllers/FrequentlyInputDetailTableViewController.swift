//
//  FrequentlyInputDetailTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 8. 5..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class FrequentlyInputDetailTableViewController: DetailBaseTableViewController {
    enum Mode {
        case Edit
        case Complete
    }
    
    private var mode = Mode.Edit
    
    private var titleTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemTitleIndex = 1
        moneyIndex = 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("SelectableCell", forIndexPath: indexPath) as! SelectableTableViewCell
            let frequentlyInputViewController = parentViewController as! FrequentlyInputDetailViewController
            
            cell.promptLabel.text = NSLocalizedString("슬롯 번호", comment: "슬롯 번호")
            cell.titleLabel.text = String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), frequentlyInputViewController.slotNumber!)
            
            return cell
        case 1:
            return configureItemTitleCell(tableView.dequeueReusableCellWithIdentifier("TextFieldCell", forIndexPath: indexPath) as! TextFieldTableViewCell, index: indexPath.row)
        case 2:
            return configureMoneyCell(tableView.dequeueReusableCellWithIdentifier("TextFieldCell", forIndexPath: indexPath) as! TextFieldTableViewCell, index: indexPath.row)
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("SelectableCell", forIndexPath: indexPath) as! SelectableTableViewCell
            let parent = parentViewController as! DetailBaseViewController
            
            cell.promptLabel.text = NSLocalizedString("왼쪽", comment: "왼쪽")
            cell.titleLabel.text = parent.leftTitle()
            
            return cell
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier("SelectableCell", forIndexPath: indexPath) as! SelectableTableViewCell
            let parent = parentViewController as! DetailBaseViewController
            
            cell.promptLabel.text = NSLocalizedString("오른쪽", comment: "오른쪽")
            cell.titleLabel.text = parent.rightTitle()
            
            return cell
        case 5:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextFieldCell", forIndexPath: indexPath) as! TextFieldTableViewCell
            let frequentlyInputViewController = parentViewController as! FrequentlyInputDetailViewController
            
            cell.promptLabel.text = NSLocalizedString("검색용 키워드", comment: "검색용 키워드")
            cell.textField.placeholder = NSLocalizedString("검색용 키워드", comment: "검색용 키워드")
            cell.textField.text = frequentlyInputViewController.searchKeyword
            cell.textField.returnKeyType = .Done
            
            return configureTextFieldCell(cell, index: indexPath.row)
        default:
            return tableView.dequeueReusableCellWithIdentifier("NotCell", forIndexPath: indexPath)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            parentViewController?.performSegueWithIdentifier("selectSlotNumber", sender: nil)
        case 3:
            parentViewController?.performSegueWithIdentifier("selectLeft", sender: nil)
        case 4:
            parentViewController?.performSegueWithIdentifier("selectRight", sender: nil)
        default:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! TextFieldTableViewCell
            
            cell.textField.becomeFirstResponder()
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        editingTextField?.resignFirstResponder()
    }
    
    // MARK: - TextFieldTableViewCellDelegate methods
    
    override func didPrevTouch(cell: TextFieldTableViewCell) {
        switch cell.textField.tag {
        case 1:
            changeFirstResponderTo(5)
        case 2:
            changeFirstResponderTo(1)
        case 5:
            changeFirstResponderTo(2)
        default:
            break
        }
    }
    
    override func didNextTouch(cell: TextFieldTableViewCell) {
        switch cell.textField.tag {
        case 1:
            changeFirstResponderTo(2)
        case 2:
            changeFirstResponderTo(5)
        case 5:
            changeFirstResponderTo(1)
        default:
            break
        }
    }
    
    override func didReturnKeyTouch(cell: TextFieldTableViewCell) {
        switch cell.textField.tag {
        case 1:
            didNextTouch(cell)
        default:
            cell.textField.resignFirstResponder()
        }
    }
    
    // MARK: - UITextFieldDelegate methods
    
    override func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        let frequentlyInputViewController = parentViewController as! FrequentlyInputDetailViewController
        
        frequentlyInputViewController.searchKeyword = textField.text
    }
}
