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
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let parentViewController = parent as! FrequentlyInputDetailViewController
        
        switch parentViewController.mode {
        case .complete:
            return super.tableView(tableView, numberOfRowsInSection: section) - 1
        case .edit:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var row: Int
        let parentViewController = parent as! FrequentlyInputDetailViewController
        
        switch parentViewController.mode {
        case .complete:
            row = indexPath.row + 1
        case .edit:
            row = indexPath.row
        }
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell
            let frequentlyInputViewController = parent as! FrequentlyInputDetailViewController
            
            cell.promptLabel.text = NSLocalizedString("슬롯 번호", comment: "슬롯 번호")
            cell.titleLabel.text = String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), frequentlyInputViewController.slotNumber!)
            
            return cell
        case 1:
            return configureItemTitleCell(tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell, index: row)
        case 2:
            return configureMoneyCell(tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell, index: row)
        case 3:
            return configureLeftCell(tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell)
        case 4:
            return configureRightCell(tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell)
        case 5:
            switch parentViewController.mode {
            case .edit:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell
                let frequentlyInputViewController = parent as! FrequentlyInputDetailViewController
                
                cell.promptLabel.text = NSLocalizedString("검색용 키워드", comment: "검색용 키워드")
                cell.textField.placeholder = NSLocalizedString("검색용 키워드", comment: "검색용 키워드")
                cell.textField.text = frequentlyInputViewController.searchKeyword
                cell.textField.returnKeyType = .done
                
                return configureTextFieldCell(cell, index: row)
            case .complete:
                return configureMemoCell(tableView.dequeueReusableCell(withIdentifier: "MemoCell", for: indexPath) as! MemoTableViewCell)
            }
        default:
            return tableView.dequeueReusableCell(withIdentifier: "NotCell", for: indexPath)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var row: Int
        let parentViewController = parent as! FrequentlyInputDetailViewController
        
        switch parentViewController.mode {
        case .complete:
            row = indexPath.row + 1
        case .edit:
            row = indexPath.row
        }
        switch row {
        case 0:
            parentViewController.performSegue(withIdentifier: "selectSlotNumber", sender: nil)
        case 1, 2:
            let cell = tableView.cellForRow(at: indexPath) as! TextFieldTableViewCell
            
            cell.textField.becomeFirstResponder()
        case 3:
            parentViewController.performSegue(withIdentifier: "selectLeft", sender: nil)
        case 4:
            parentViewController.performSegue(withIdentifier: "selectRight", sender: nil)
        case 5:
            switch parentViewController.mode {
            case .edit:
                let cell = tableView.cellForRow(at: indexPath) as! TextFieldTableViewCell
                
                cell.textField.becomeFirstResponder()
            case .complete:
                let cell = tableView.cellForRow(at: indexPath) as! MemoTableViewCell
                
                cell.textView.becomeFirstResponder()
            }
        default:
            break
        }
    }
    
    // MARK: - TextFieldTableViewCellDelegate methods
    
    override func didPrevTouch(_ cell: TextFieldTableViewCell) {
        var targetRow: Int
        
        switch cell.textField.tag {
        case itemTitleIndex:
            targetRow = memoIndex
        case moneyIndex:
            targetRow = itemTitleIndex
        case memoIndex:
            targetRow = moneyIndex
        default:
            return
        }
        
        let parentViewController = parent as! FrequentlyInputDetailViewController
        
        if parentViewController.mode == .complete {
            if targetRow == memoIndex {
                targetRow = itemTitleIndex
            } else {
                targetRow -= 1
            }
        }
        changeFirstResponderTo(targetRow)
    }
    
    override func didNextTouch(_ cell: TextFieldTableViewCell) {
        var targetRow: Int
        
        switch cell.textField.tag {
        case itemTitleIndex:
            targetRow = moneyIndex
        case moneyIndex:
            targetRow = memoIndex
        case memoIndex:
            targetRow = itemTitleIndex
        default:
            return
        }
        
        let parentViewController = parent as! FrequentlyInputDetailViewController
        
        if parentViewController.mode == .complete {
            if targetRow == memoIndex {
                targetRow = itemTitleIndex - 1
            } else {
                targetRow -= 1
            }
        }
        changeFirstResponderTo(targetRow)
    }
    
    // MARK: - UITextFieldDelegate methods
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        if textField.tag == memoIndex {
            let frequentlyInputViewController = parent as! FrequentlyInputDetailViewController
            
            frequentlyInputViewController.searchKeyword = textField.text
        }
    }
}
