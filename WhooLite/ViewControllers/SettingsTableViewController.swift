//
//  SettingsTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 13..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = true
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged), name: NSNotification.Name.init(Notifications.showSlotNumbersChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged), name: NSNotification.Name.init(Notifications.frequentlyInputSortOrderChanged), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            return -1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "LogoutCell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let userDefaults = UserDefaults.standard

        switch indexPath.row {
        case 0:
            var slotNumbers = userDefaults.object(forKey: PreferenceKeyValues.showSlotNumbers) as? Array<Int>
            var detailText: String
            
            if slotNumbers == nil || slotNumbers!.count == 0 {
                slotNumbers = [1, 2, 3]
            }
            if slotNumbers!.count == 3 {
                detailText = NSLocalizedString("모든", comment: "모든")
            } else {
                var first = true
                
                slotNumbers?.sort()
                detailText = ""
                for slotNumber in slotNumbers! {
                    if first {
                        first = false
                    } else {
                        detailText += ", "
                    }
                    detailText += String.init(format: NSLocalizedString("%1$d번", comment: "슬롯 번호"), slotNumber)
                }
            }
            cell.textLabel?.text = NSLocalizedString("표시할 자주입력 거래 슬롯 번호", comment: "슬롯 번호")
            cell.detailTextLabel?.text = detailText + " " + NSLocalizedString("슬롯", comment: "슬롯")
        case 1:
            let sortOrder = PreferenceKeyValues.FrequentlyInputSortOrder.init(rawValue: userDefaults.integer(forKey: PreferenceKeyValues.frequentlyInputSortOrder))
            
            cell.textLabel?.text = NSLocalizedString("자주입력 거래 정렬 방식", comment: "정렬 방식")
            switch sortOrder {
            case .serverSettings:
                cell.detailTextLabel?.text = NSLocalizedString("서버에 설정된대로", comment: "서버 설정순")
            case .frequentlyUse:
                cell.detailTextLabel?.text = NSLocalizedString("자주사용한 순서로", comment: "자주 사용순")
            case .lastUse:
                cell.detailTextLabel?.text = NSLocalizedString("최근 사용한 순서로", comment: "최근 사용순")
            }
        default:
            break
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "selectShowSlotNumbers", sender: nil)
            case 1:
                performSegue(withIdentifier: "selectSortOrder", sender: nil)
            default:
                break
            }
        case 1:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.logout()
        default:
            break
        }
    }
    
    // MARK: - Notification handler methods
    
    func settingChanged() {
        tableView.reloadData()
    }
}
