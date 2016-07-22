//
//  WhooLiteTabBarItemBaseTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class WhooLiteTabBarItemBaseTableViewController: UITableViewController {
    var sectionId: String?
    var sectionTitles: [String]?
    var sectionDataCounts: [Int]?
    
    private var section: Results<Section>?
    private var sectionNotificationToken: NotificationToken?
    private var sectionReady = false
    private var accountsReady = false
    private var numberFormatter: NSNumberFormatter?
    private var accounts: Results<Account>?
    private var accountsNotificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        setCurrentSectionId(userDefaults.objectForKey(PreferenceKeys.currentSectionId) as? String)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(sectionChangedHandler), name: Notifications.sectionIdChanged, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        sectionReady = false
        accountsReady = false
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        sectionNotificationToken?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        refreshSections()
        
        if let titles = sectionTitles {
            return titles.count
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionDataCounts![section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        cell.textLabel?.text = dataTitle(indexPath)

        return cell
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

    // MARK: - Notification handlers
    
    func sectionChangedHandler(notification: NSNotification) {
        let _sectionId = notification.userInfo?[Notifications.sectionId] as! String
        
        if sectionId == nil || _sectionId != sectionId! {
            setCurrentSectionId(_sectionId)
            refreshMainData()
            sectionChanged()
        }
    }
    
    // MARK: - Instance methods
    
    func setCurrentSectionId(_sectionId: String?) {
        if _sectionId != nil {
            sectionId = _sectionId
            accounts = try! Realm().objects(Account.self).filter("sectionId == %@", sectionId!)
            accountsNotificationToken?.stop()
            accountsNotificationToken = accounts?.addNotificationBlock({changes in
                switch changes {
                case .Initial:
                    break
                default:
                    objc_sync_enter(self)
                    self.accountsReady = true
                    if self.sectionReady {
                        self.refreshMainData()
                    }
                    objc_sync_exit(self)
                }
            })
            
            let _section = try! Realm().objects(Section.self).filter("sectionId == %@", sectionId!)
            
            if _section.count > 0 {
                sectionNotificationToken?.stop()
                sectionNotificationToken = _section.addNotificationBlock({changes in
                    switch changes {
                    case .Initial:
                        break
                    default:
                        objc_sync_enter(self)
                        self.sectionReady = true
                        if self.accountsReady {
                            self.refreshMainData()
                        }
                        objc_sync_exit(self)
                    }
                })
                section = _section
            }
            getDataFromSection(_section)
        }
    }
    
    func getDataFromSection(_section: Results<Section>) {
        if _section.count > 0 {
            numberFormatter = NSNumberFormatter.init()
            numberFormatter?.numberStyle = .CurrencyStyle
            numberFormatter?.locale = NSLocale.init(localeIdentifier: _section[0].currency)
        } else {
            numberFormatter = nil
        }
    }
    
    func mainDataReceived(resultCode: Int) {
        
    }
    
    
    
    // MARK: - Abstract methods
    
    func refreshMainData() {
        preconditionFailure()
    }
    
    func sectionChanged() {
        preconditionFailure()
    }
    
    func refreshSections() {
        preconditionFailure()
    }
    
    func dataTitle(indexPath: NSIndexPath) -> String {
        preconditionFailure()
    }
}
