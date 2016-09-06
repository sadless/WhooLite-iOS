//
//  DetailBaseTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 8. 5..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class DetailBaseTableViewController: UITableViewController, UITextFieldDelegate, TextFieldTableViewCellDelegate {
    var itemTitleIndex: Int?
    var moneyIndex: Int?
    var firstResponderIndex = -1
    
    var editingTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.toolbarHidden = false
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
    
    func changeFirstResponderTo(toIndex: Int) {
        let indexPath = NSIndexPath.init(forRow: toIndex, inSection: 0)
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? TextFieldTableViewCell
        
        if let c = cell {
            c.textField.becomeFirstResponder()
        } else {
            firstResponderIndex = toIndex
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
        }
    }
    
    func checkFristResponder(cell: TextFieldTableViewCell, index: Int) {
        if firstResponderIndex == index {
            cell.textField.becomeFirstResponder()
            firstResponderIndex = -1
        }
    }
    
    func configureTextFieldCell(cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        cell.textField.delegate = self
        cell.textField.tag = index
        checkFristResponder(cell, index: index)
        cell.delegate = self
        
        return cell
    }
    
    func configureItemTitleCell(cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        let parent = parentViewController as! DetailBaseViewController
        
        parent.configureItemTitleCell(cell)
        
        return configureTextFieldCell(cell, index: index)
    }
    
    func configureMoneyCell(cell: TextFieldTableViewCell, index: Int) -> TextFieldTableViewCell {
        let parent = parentViewController as! DetailBaseViewController
        
        parent.configureMoneyCell(cell)
        
        return configureTextFieldCell(cell, index: index)
    }
    
    // MARK: - TextFieldTableViewCellDelegate methods
    
    func didPrevTouch(cell: TextFieldTableViewCell) {
        preconditionFailure()
    }
    
    func didNextTouch(cell: TextFieldTableViewCell) {
        preconditionFailure()
    }
    
    func didReturnKeyTouch(cell: TextFieldTableViewCell) {
        preconditionFailure()
    }
    
    // MARK: - UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        editingTextField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let parent = parentViewController as! DetailBaseViewController
        
        switch textField.tag {
        case itemTitleIndex!:
            parent.itemTitle = textField.text
        default:
            break
        }
        editingTextField = nil
    }
}
