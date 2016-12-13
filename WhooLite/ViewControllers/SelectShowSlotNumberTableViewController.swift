//
//  SelectShowSlotNumberTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 14..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class SelectShowSlotNumberTableViewController: UITableViewController {
    var slotNumbers: Array<Int>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let userDefaults = UserDefaults.standard
        
        slotNumbers = userDefaults.object(forKey: PreferenceKeyValues.showSlotNumbers) as? Array<Int>
        if slotNumbers == nil || slotNumbers!.count == 0 {
            slotNumbers = [1, 2, 3]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), indexPath.row + 1)
        if slotNumbers!.contains(indexPath.row + 1) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
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
        if slotNumbers!.contains(indexPath.row + 1) {
            slotNumbers?.remove(at: slotNumbers!.index(of: indexPath.row + 1)!)
        } else {
            slotNumbers?.append(indexPath.row + 1)
        }
        
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(slotNumbers!, forKey: PreferenceKeyValues.showSlotNumbers)
        userDefaults.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name.init(Notifications.showSlotNumbersChanged), object: nil)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
