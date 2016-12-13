//
//  DetailBaseTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 8. 5..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class DetailBaseTableViewController: UITableViewController, UITextFieldDelegate, TextFieldTableViewCellDelegate, UITextViewDelegate {
    let itemTitleIndex = 1
    let moneyIndex = 2
    let memoIndex = 5
    
    var firstResponderIndex = -1
    var editingTextField: UITextField?
    var editingTextView: UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
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
    
    func changeFirstResponderTo(_ toIndex: Int) {
        let indexPath = IndexPath.init(row: toIndex, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
        
        if let c = cell {
            c.textField.becomeFirstResponder()
        } else {
            firstResponderIndex = toIndex
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
    }
    
    func checkFirstResponder(_ cell: TextFieldTableViewCell, index: Int) {
        if firstResponderIndex == index {
            DispatchQueue.main.async {
                cell.textField.becomeFirstResponder()
            }
            firstResponderIndex = -1
        }
    }
    
    func configureTextFieldCell(_ cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        cell.textField.delegate = self
        cell.textField.tag = index
        checkFirstResponder(cell, index: index)
        cell.delegate = self
        
        return cell
    }
    
    func configureItemTitleCell(_ cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        let parentViewController = parent as! DetailBaseViewController
        
        return configureTextFieldCell(parentViewController.configureItemTitleCell(cell), index: index)
    }
    
    func configureMoneyCell(_ cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        let parentViewController = parent as! DetailBaseViewController
        
        return configureTextFieldCell(parentViewController.configureMoneyCell(cell), index: index)
    }
    
    func configureLeftCell(_ cell: SelectableTableViewCell) -> SelectableTableViewCell {
        let parentViewController = parent as! DetailBaseViewController
        
        cell.promptLabel.text = NSLocalizedString("왼쪽", comment: "왼쪽")
        cell.titleLabel.text = parentViewController.leftTitle()
        
        return cell
    }
    
    func configureRightCell(_ cell: SelectableTableViewCell) -> SelectableTableViewCell {
        let parentViewController = parent as! DetailBaseViewController
        
        cell.promptLabel.text = NSLocalizedString("오른쪽", comment: "오른쪽")
        cell.titleLabel.text = parentViewController.rightTitle()
        
        return cell
    }
    
    func configureMemoCell(_ cell: MemoTableViewCell) -> MemoTableViewCell {
        let parentViewController = parent as! DetailBaseViewController
        
        cell.textView.text = parentViewController.memo
        cell.textView.delegate = self
        
        return cell
    }
    
    // MARK: - TextFieldTableViewCellDelegate methods
    
    func didPrevTouch(_ cell: TextFieldTableViewCell) {
        preconditionFailure()
    }
    
    func didNextTouch(_ cell: TextFieldTableViewCell) {
        preconditionFailure()
    }
    
    func didReturnKeyTouch(_ cell: TextFieldTableViewCell) {
        switch cell.textField.tag {
        case itemTitleIndex:
            didNextTouch(cell)
        default:
            cell.textField.resignFirstResponder()
        }
    }
    
    // MARK: - UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editingTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let parentViewController = parent as! DetailBaseViewController
        
        switch textField.tag {
        case itemTitleIndex:
            parentViewController.itemTitle = textField.text
        case moneyIndex:
            parentViewController.money = textField.text!
        default:
            break
        }
        editingTextField = nil
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView != editingTextView {
            editingTextField?.resignFirstResponder()
            editingTextView?.resignFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == memoIndex {
            return 110
        } else {
            return 44
        }
    }
    
    // MARK: - UITextViewDelegate methods
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        editingTextView = textView
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let parentViewController = parent as! DetailBaseViewController
        
        parentViewController.memo = textView.text
        editingTextView = nil
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
}
