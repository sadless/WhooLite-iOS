//
//  HistoryDetailTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 3..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class HistoryDetailTableViewController: DetailBaseTableViewController {
    var sectionDateFormat: DateFormatter?
    var datePickerShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userDefaults = UserDefaults.standard
        let section = try! Realm().objects(Section.self).filter("sectionId == %@", userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) as! String).first!
        
        sectionDateFormat = DataUtility.dateFormat(from: section.dateFormat)
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

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if datePickerShown {
            return super.tableView(tableView, numberOfRowsInSection: 0) + 1
        } else {
            return super.tableView(tableView, numberOfRowsInSection: 0)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let parentViewController = parent as! HistoryDetailViewController
        var row: Int
        
        if datePickerShown && indexPath.row > 0 {
            row = indexPath.row - 1
        } else {
            row = indexPath.row
        }

        switch row {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell
                
                cell.promptLabel.text = NSLocalizedString("날짜", comment: "날짜")
                cell.titleLabel.text = sectionDateFormat?.string(from: parentViewController.entryDateFormat.date(from: String(parentViewController.entryDate!))!)
                
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "DatePickerCell", for: indexPath) as! DatePickerTableViewCell
                
                cell.datePicker.date = parentViewController.entryDateFormat.date(from: String(parentViewController.entryDate!))!
                if cell.datePicker.allTargets.count == 0 {
                    cell.datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
                }
                
                return cell
            default:
                return tableView.dequeueReusableCell(withIdentifier: "NotCell", for: indexPath)
            }
        case 1:
            return configureItemTitleCell(tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell, index: row)
        case 2:
            return configureMoneyCell(tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldTableViewCell, index: row)
        case 3:
            return configureLeftCell(tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell)
        case 4:
            return configureRightCell(tableView.dequeueReusableCell(withIdentifier: "SelectableCell", for: indexPath) as! SelectableTableViewCell)
        case 5:
            return configureMemoCell(tableView.dequeueReusableCell(withIdentifier: "MemoCell", for: indexPath) as! MemoTableViewCell)
        default:
            return tableView.dequeueReusableCell(withIdentifier: "NotCell", for: indexPath)
        }
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var row: Int
        
        if datePickerShown && indexPath.row > 0 {
            row = indexPath.row - 1
        } else {
            row = indexPath.row
        }
        switch row {
        case 0:
            if indexPath.row == 0 {
                datePickerShown = !datePickerShown
                if datePickerShown {
                    tableView.insertRows(at: [IndexPath.init(row: 1, section: 0)], with: .fade)
                } else {
                    tableView.deleteRows(at: [IndexPath.init(row: 1, section: 0)], with: .fade)
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case 1, 2:
            let cell = tableView.cellForRow(at: indexPath) as! TextFieldTableViewCell
            
            cell.textField.becomeFirstResponder()
        case 3:
            parent?.performSegue(withIdentifier: "selectLeft", sender: nil)
        case 4:
            parent?.performSegue(withIdentifier: "selectRight", sender: nil)
        case 5:
            let cell = tableView.cellForRow(at: indexPath) as! MemoTableViewCell
            
            cell.textView.becomeFirstResponder()
        default:
            break
        }
    }
    
    // MARK: - TextFieldTableViewCellDelegate methods
    
    override func didPrevTouch(_ cell: TextFieldTableViewCell) {
        var targetRow: Int
        
        switch cell.textField.tag {
        case itemTitleIndex:
            targetRow = moneyIndex
        case moneyIndex:
            targetRow = itemTitleIndex
        default:
            return
        }
        if datePickerShown {
            targetRow += 1
        }
        changeFirstResponderTo(targetRow)
    }
    
    override func didNextTouch(_ cell: TextFieldTableViewCell) {
        var targetRow: Int
        
        switch cell.textField.tag {
        case itemTitleIndex:
            targetRow = moneyIndex
        case moneyIndex:
            targetRow = itemTitleIndex
        default:
            return
        }
        if datePickerShown {
            targetRow += 1
        }
        changeFirstResponderTo(targetRow)
    }
    
    // MARK: - Instance methods
    
    func dateChanged(sender: UIDatePicker) {
        let parentViewController = parent as! HistoryDetailViewController
        
        parentViewController.entryDate = Int(parentViewController.entryDateFormat.string(from: sender.date))
        tableView.reloadRows(at: [IndexPath.init(row: 0, section: 0)], with: .none)
    }
}
