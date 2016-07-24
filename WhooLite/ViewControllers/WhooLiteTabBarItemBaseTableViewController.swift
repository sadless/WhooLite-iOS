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
    let accountPredicateFormat = "sectionId == %@ AND accountType == %@ AND accountId == %@"
    
    var sectionId: String?
    var sectionTitles: [String]?
    var sectionDataCounts: [Int]?
    var receiveFailedText: String?
    var noDataText: String?
    
    private var section: Results<Section>?
    private var sectionNotificationToken: NotificationToken?
    private var sectionReady = false
    private var accountsReady = false
    private var numberFormatter: NSNumberFormatter?
    private var accounts: Results<Account>?
    private var accountsNotificationToken: NotificationToken?
    private var received = false
    private var failed = false
    private var realm = try! Realm()
    
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
        
        if sectionDataCounts?[0] == 0 {
            if tableView.backgroundView == nil {
                let nib = NSBundle.mainBundle().loadNibNamed("NoDataView", owner: self, options: nil)
                
                tableView.backgroundView = nib[0] as? UIView
                (tableView.backgroundView as! NoDataView).retryButton.addTarget(self, action: #selector(retryTouched), forControlEvents: .TouchUpInside)
            }
            
            let noDataView = tableView.backgroundView as! NoDataView
            
            if failed {
                noDataView.textLabel.text = receiveFailedText
            } else if received {
                noDataView.textLabel.text = noDataText
            }
            noDataView.activityIndicator.hidden = failed || received
            noDataView.textLabel.hidden = !noDataView.activityIndicator.hidden
            noDataView.retryButton.hidden = !noDataView.activityIndicator.hidden
            tableView.backgroundView?.hidden = false
            tableView.separatorStyle = .None
        } else {
            tableView.backgroundView?.hidden = true
            tableView.separatorStyle = .SingleLine
        }
        
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! InputBaseTableViewCell
        let money = dataMoney(indexPath)
        let leftAccountType = dataLeftAccountType(indexPath)
        let rightAccountType = dataRightAccountType(indexPath)

        cell.titleLabel.text = dataTitle(indexPath)
        if money < WhooingKeyValues.epsilon {
            cell.moneyLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        } else {
            if let formatter = numberFormatter {
                cell.moneyLabel.text = formatter.stringFromNumber(NSNumber.init(double: money))
            } else {
                cell.moneyLabel.text = NSLocalizedString("(알 수 없음)", comment: "알 수 없음")
            }
        }
        if leftAccountType.characters.count > 0 {
            let leftAccount = realm.objects(Account.self).filter(accountPredicateFormat, sectionId!, leftAccountType, dataLeftAccountId(indexPath)).first
            var leftAccountTitle: String? = nil
            
            if let account = leftAccount {
                leftAccountTitle = account.title
            }
            if let accountTitle = leftAccountTitle {
                switch leftAccountType {
                case WhooingKeyValues.assets:
                    leftAccountTitle  = accountTitle + "+"
                case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
                    leftAccountTitle  = accountTitle + "-"
                default:
                    break
                }
                cell.leftLabel.text = leftAccountTitle!
            } else {
                cell.leftLabel.text = NSLocalizedString("(알 수 없음)", comment: "알 수 없음")
            }
        } else {
            cell.leftLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }
        if rightAccountType.characters.count > 0 {
            let rightAccount = realm.objects(Account.self).filter(accountPredicateFormat, sectionId!, rightAccountType, dataRightAccountId(indexPath)).first
            var rightAccountTitle: String? = nil
            
            if let account = rightAccount {
                rightAccountTitle = account.title
            }
            if let accountTitle = rightAccountTitle {
                switch rightAccountType {
                case WhooingKeyValues.assets:
                    rightAccountTitle  = accountTitle + "-"
                case WhooingKeyValues.liabilities, WhooingKeyValues.capital:
                    rightAccountTitle  = accountTitle + "-"
                default:
                    break
                }
                cell.rightLabel.text = rightAccountTitle!
            } else {
                cell.rightLabel.text = NSLocalizedString("(알 수 없음)", comment: "알 수 없음")
            }
        } else {
            cell.rightLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let titles = sectionTitles {
            return titles[section]
        } else {
            return nil
        }
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
            accounts = realm.objects(Account.self).filter("sectionId == %@", sectionId!)
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
            
            let _section = realm.objects(Section.self).filter("sectionId == %@", sectionId!)
            
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
                title = String.init(format: NSLocalizedString("%1$@(%2$@)", comment: "섹션명"), _section[0].title, _section[0].currency)
            }
            getDataFromSection(_section)
        }
    }
    
    func getDataFromSection(_section: Results<Section>) {
        if _section.count > 0 {
            numberFormatter = NSNumberFormatter.init()
            numberFormatter?.numberStyle = .CurrencyStyle
            numberFormatter?.currencyCode = _section[0].currency
        } else {
            numberFormatter = nil
        }
    }
    
    func mainDataReceived(resultCode: Int) {
        if resultCode > 0 {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                received = true
                failed = false
            } else {
                failed = true
            }
        }
    }
    
    func retryTouched(sender: AnyObject) {
        received = false
        failed = false
        tableView.reloadData()
        refreshMainData()
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
    
    func dataMoney(indexPath: NSIndexPath) -> Double {
        preconditionFailure()
    }
    
    func dataLeftAccountType(indexPath: NSIndexPath) -> String {
        preconditionFailure()
    }
    
    func dataLeftAccountId(indexPath: NSIndexPath) -> String {
        preconditionFailure()
    }
    
    func dataRightAccountType(indexPath: NSIndexPath) -> String {
        preconditionFailure()
    }
    
    func dataRightAccountId(indexPath: NSIndexPath) -> String {
        preconditionFailure()
    }
}
