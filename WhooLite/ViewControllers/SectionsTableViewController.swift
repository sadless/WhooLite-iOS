//
//  SectionsTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 25..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class SectionsTableViewController: UITableViewController {
    var sections: Results<Section>?
    var sectionsNotificationToken: NotificationToken?
    var currentSectionId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        sections = try! Realm().objects(Section.self).sorted(byProperty: "sortOrder", ascending: true)
        sectionsNotificationToken = sections?.addNotificationBlock({changes in
            switch changes {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                self.tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                self.tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                self.tableView.endUpdates()
            case .error(let error):
                fatalError("\(error)")
            }
        })
        currentSectionId = UserDefaults.standard.object(forKey: PreferenceKeyValues.currentSectionId) as? String
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.init(Notifications.logout), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let sectionId = currentSectionId {
            for i in 0..<(sections?.count)! {
                let section = sections?[i];
                
                if section?.sectionId == sectionId {
                    tableView.scrollToRow(at: IndexPath.init(row: i, section: 0), at: .middle, animated: true)
                }
            }
        }
    }
    
    deinit {
        sectionsNotificationToken?.stop()
        NotificationCenter.default.removeObserver(self)
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
        return (sections?.count)!
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let section = sections![indexPath.row]

        cell.textLabel?.text = String.init(format: NSLocalizedString("%1$@(%2$@)", comment: "섹션명"), section.title, section.currency)
        cell.detailTextLabel?.text = section.memo
        if let sectionId = currentSectionId, sectionId == section.sectionId {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userDefaults = UserDefaults.standard
        let section = sections![indexPath.row]
        
        if section.sectionId != userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) as! String {
            userDefaults.set(section.sectionId, forKey: PreferenceKeyValues.currentSectionId)
            userDefaults.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.sectionIdChanged), object: nil, userInfo: [Notifications.sectionId: section.sectionId])
        }
        let _ = navigationController?.popViewController(animated: true)
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

    // MARK: - Notification handler methods
    
    func logout() {
        sectionsNotificationToken?.stop()
    }
}
