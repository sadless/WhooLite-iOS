//
//  WhooLiteTabBarItemBaseTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

class WhooLiteTabBarItemBaseTableViewController: UITableViewController {
    let accountPredicateFormat = "sectionId == %@ AND accountType == %@ AND accountId == %@"
    let entryDateFormat = DateFormatter.init()
    
    var sectionId: String?
    var sectionTitles = [String]()
    var sectionDataCounts = [Int]()
    var receiveFailedText: String?
    var noDataText: String?
    var searching = false
    var deleteConfirmString: String?
    var tabBarItemIndex = 0
    var selectedIndexPaths: [IndexPath]?
    
    fileprivate var section: Results<Section>?
    fileprivate var sectionNotificationToken: NotificationToken?
    fileprivate var sectionReady = false
    fileprivate var accountsReady = false
    fileprivate var numberFormatter: NumberFormatter?
    fileprivate var accounts: Results<Account>?
    fileprivate var accountsNotificationToken: NotificationToken?
    fileprivate var received = false
    fileprivate var failed = false
    fileprivate var realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        entryDateFormat.dateFormat = "yyyyMMdd"
        
        let userDefaults = UserDefaults.standard
        
        setCurrentSectionId(userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) as? String)
        NotificationCenter.default.addObserver(self, selector: #selector(sectionChangedHandler), name: Notification.Name(rawValue: Notifications.sectionIdChanged), object: nil)
        clearsSelectionOnViewWillAppear = true
        tableView.estimatedRowHeight = 76
        tableView.rowHeight = UITableViewAutomaticDimension
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.init(Notifications.logout), object: nil)
    }
    
    deinit {
        sectionNotificationToken?.stop()
        accountsNotificationToken?.stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        sectionReady = false
        accountsReady = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if sectionDataCounts.count == 0 {
            if tableView.backgroundView == nil {
                let nib = Bundle.main.loadNibNamed("NoDataView", owner: self, options: nil)
                
                tableView.backgroundView = nib?[0] as? UIView
                (tableView.backgroundView as! NoDataView).retryButton.addTarget(self, action: #selector(retryTouched), for: .touchUpInside)
            }
            
            let noDataView = tableView.backgroundView as! NoDataView
            
            if failed {
                noDataView.textLabel.text = receiveFailedText
            } else if received {
                noDataView.textLabel.text = noDataText
            }
            noDataView.activityIndicator.isHidden = failed || received
            noDataView.textLabel.isHidden = !noDataView.activityIndicator.isHidden
            noDataView.retryButton.isHidden = !noDataView.activityIndicator.isHidden || searching
            tableView.backgroundView?.isHidden = false
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView?.isHidden = true
            tableView.separatorStyle = .singleLine
        }
        
        if sectionTitles.count > 0 {
            return sectionTitles.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionDataCounts.count == 0 {
            return 0
        } else {
            return sectionDataCounts[section]
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! InputBaseTableViewCell
        let money = dataMoney(indexPath)
        let leftAccountType = dataLeftAccountType(indexPath)
        let rightAccountType = dataRightAccountType(indexPath)

        cell.titleLabel.text = dataTitle(indexPath)
        if money < WhooingKeyValues.epsilon {
            cell.moneyLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        } else {
            if let formatter = numberFormatter {
                cell.moneyLabel.text = formatter.string(from: NSNumber.init(value: money as Double))
            } else {
                cell.moneyLabel.text = NSLocalizedString("(알 수 없음)", comment: "알 수 없음")
            }
        }
        if !leftAccountType.isEmpty {
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
            }
        } else {
            cell.leftLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }
        if !rightAccountType.isEmpty {
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
            }
        } else {
            cell.rightLabel.text = NSLocalizedString("(지정 안 됨)", comment: "지정 안 됨")
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sectionTitles.count > 0 {
            return sectionTitles[section]
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
    
    func sectionChangedHandler(_ notification: Notification) {
        let _sectionId = notification.userInfo?[Notifications.sectionId] as! String
        
        if sectionId == nil || _sectionId != sectionId! {
            setCurrentSectionId(_sectionId)
            refreshMainData()
            sectionChanged()
        }
    }
    
    // MARK: - Instance methods
    
    func setCurrentSectionId(_ _sectionId: String?) {
        if _sectionId != nil {
            sectionId = _sectionId
            accounts = realm.objects(Account.self).filter("sectionId == %@", sectionId!)
            accountsNotificationToken?.stop()
            accountsNotificationToken = accounts?.addNotificationBlock({changes in
                var needCheck: Bool
                
                switch changes {
                case .initial:
                    needCheck = (self.tabBarController as! WhooLiteViewController).isAccountReceived
                default:
                    needCheck = true
                }
                if needCheck {
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
                    var needCheck: Bool
                    
                    switch changes {
                    case .initial:
                        needCheck = (self.tabBarController as! WhooLiteViewController).isSectionReceived
                    default:
                        needCheck = true
                    }
                    if needCheck {
                        objc_sync_enter(self)
                        self.sectionReady = true
                        if self.accountsReady {
                            self.refreshMainData()
                        }
                        objc_sync_exit(self)
                    }
                })
                section = _section

                let tabBarItemTitle = tabBarController?.tabBar.items![tabBarItemIndex].title
                
                title = String.init(format: NSLocalizedString("%1$@(%2$@)", comment: "섹션명"), _section[0].title, _section[0].currency)
                parent?.title = title
                tabBarController?.tabBar.items![tabBarItemIndex].title = tabBarItemTitle
            }
            getDataFromSection(_section)
        }
    }
    
    func getDataFromSection(_ _section: Results<Section>) {
        if _section.count > 0 {
            numberFormatter = NumberFormatter.init()
            numberFormatter?.numberStyle = .currency
            numberFormatter?.currencyCode = _section[0].currency
        } else {
            numberFormatter = nil
        }
    }
    
    func mainDataReceived(_ resultCode: Int) {
        if resultCode > 0 {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                received = true
                failed = false
            } else {
                failed = true
            }
        }
    }
    
    func retryTouched(_ sender: AnyObject) {
        received = false
        failed = false
        tableView.reloadData()
        refreshMainData()
    }
    
    func deleteSelectedItems() {
        let alertController = UIAlertController.init(title: NSLocalizedString("삭제 확인", comment: "삭제 확인"), message: String.init(format: deleteConfirmString!, tableView.indexPathsForSelectedRows!.count), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("삭제", comment: "삭제"), style: .default, handler: { action in
            SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
            self.selectedIndexPaths = self.tableView.indexPathsForSelectedRows
            self.deleteCall()
        }))
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func didDeleteSelectedItems(resultCode: Int) {
        SVProgressHUD.dismiss()
        
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("삭제 실패", comment: "삭제 실패"), message: NSLocalizedString("선택하신 항목을 삭제하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "삭제 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: { action in
                SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
                self.deleteCall()
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if let parentViewController = parent as? WhooLiteTabBarItemBaseViewController {
                parentViewController.cancelTouched(parentViewController.cancelButton)
                tableView.reloadData()
            } else {
                var toViewController: UIViewController!
                
                for viewController in navigationController!.viewControllers {
                    if viewController is WhooLiteTabBarItemBaseViewController {
                        toViewController = viewController
                        break
                    }
                }
                let _ = navigationController?.popToViewController(toViewController, animated: true)
            }
        }
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
    
    func dataTitle(_ indexPath: IndexPath) -> String {
        preconditionFailure()
    }
    
    func dataMoney(_ indexPath: IndexPath) -> Double {
        preconditionFailure()
    }
    
    func dataLeftAccountType(_ indexPath: IndexPath) -> String {
        preconditionFailure()
    }
    
    func dataLeftAccountId(_ indexPath: IndexPath) -> String {
        preconditionFailure()
    }
    
    func dataRightAccountType(_ indexPath: IndexPath) -> String {
        preconditionFailure()
    }
    
    func dataRightAccountId(_ indexPath: IndexPath) -> String {
        preconditionFailure()
    }
    
    func deleteCall() {
        preconditionFailure()
    }
    
    func otherActionWithSelectedItems() {
        preconditionFailure()
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let viewController = parent as! WhooLiteTabBarItemBaseViewController
            
            viewController.otherActionButton.isEnabled = true
            viewController.deleteButton.isEnabled = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let viewController = parent as! WhooLiteTabBarItemBaseViewController
            let isEnabled = tableView.indexPathsForSelectedRows != nil && tableView.indexPathsForSelectedRows!.count > 0
            
            viewController.otherActionButton.isEnabled = isEnabled
            viewController.deleteButton.isEnabled = isEnabled
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertController = UIAlertController.init(title: NSLocalizedString("삭제 확인", comment: "삭제 확인"), message: NSLocalizedString("삭제하시겠습니까?", comment: "삭제 확안"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("삭제", comment: "삭제"), style: .default, handler: { action in
                SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기중"))
                self.selectedIndexPaths = [indexPath]
                self.deleteCall()
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Notification handler methods
    
    func logout() {
        sectionNotificationToken?.stop()
        accountsNotificationToken?.stop()
    }
}
