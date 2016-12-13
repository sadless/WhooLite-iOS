//
//  FrequentlyInputTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class FrequentlyInputTableViewController: WhooLiteTabBarItemBaseTableViewController, UISearchResultsUpdating, BackgroundSearcherDelegate, FrequentlyInputDetailTableViewControllerDelegate {
    var searchedItems: [String]?
    var frequentItems: Results<FrequentItem>?
    var frequentItemsNotificationToken: NotificationToken?
    var sortProperty: String?
    var sortAscending: Bool?
    var searchController: UISearchController?
    var progressingItemIds = [String: [String]]()
    var backgroundSearcher: BackgroundSearcher?
    var multiInputIndex = 0
    var multiInputArgs = [[String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItemIndex = 0
        receiveFailedText = NSLocalizedString("자주입력 거래들 항목을 가져오지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "실패")
        noDataText = NSLocalizedString("자주입력 거래들 항목이 없습니다. 거래내역 탭에서 항목을 만들어보세요!", comment: "데이터 없음")
        deleteConfirmString = NSLocalizedString("선택하신 %1$d개의 자주입력 거래들 항목을 삭제하시겠습니까?", comment: "삭제 확인")
        setSortOrder()
        if sectionId != nil {
            sectionChanged()
        }
        searchController = UISearchController.init(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchController?.searchBar
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged), name: NSNotification.Name.init(Notifications.showSlotNumbersChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged), name: NSNotification.Name.init(Notifications.frequentlyInputSortOrderChanged), object: nil)
    }
    
    deinit {
        frequentItemsNotificationToken?.stop()
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if let identifier = segue.identifier {
//            switch identifier {
//            case "detail":
//                let viewController = segue.destinationViewController as! FrequentlyInputDetailViewController
//                
//                viewController.frequentItem = itemAtIndexPath(tableView.indexPathForSelectedRow!)
//            default:
//                break
//            }
//        }
//    }
    
    // MARK: - Instance methods
    
    override func refreshMainData() {
        NetworkUtility.getFrequentItems(sectionId: sectionId!, completionHandler: { resultCode in
            self.mainDataReceived(resultCode)
        })
    }
    
    override func sectionChanged() {
        frequentItems = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", sectionId!)
        filtering()
    }
    
    override func refreshSections() {
        sectionTitles.removeAll()
        sectionDataCounts.removeAll()
        
        var needSection = sectionId != nil
        
        if needSection {
            needSection = (frequentItems?.count)! > 0
            if needSection {
                var slot = frequentItems?[0].slotNumber
                var count = 0
                
                for item in frequentItems! {
                    if slot == item.slotNumber {
                        count += 1
                    } else {
                        sectionTitles.append(String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), slot!))
                        sectionDataCounts.append(count)
                        slot = item.slotNumber
                        count = 1
                    }
                }
                needSection = sectionTitles.count > 0
                if needSection {
                    sectionTitles.append(String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), slot!))
                    sectionDataCounts.append(count)
                } else {
                    sectionDataCounts.append((frequentItems?.count)!)
                }
            }
        }
    }
    
    override func dataTitle(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).title
    }
    
    override func dataMoney(_ indexPath: IndexPath) -> Double {
        return itemAtIndexPath(indexPath).money
    }
    
    override func dataLeftAccountType(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountType
    }
    
    override func dataLeftAccountId(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountId
    }
    
    override func dataRightAccountType(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountType
    }
    
    override func dataRightAccountId(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountId
    }
    
    override func deleteCall() {
        var slotItemIdsMap = [Int: [String]]()
        
        for indexPath in selectedIndexPaths! {
            let item = itemAtIndexPath(indexPath)
            var itemIds = slotItemIdsMap[item.slotNumber]
            
            if itemIds == nil {
                itemIds = [String]()
            }
            itemIds?.append(item.itemId)
            slotItemIdsMap[item.slotNumber] = itemIds
        }
        NetworkUtility.deleteFrequentItems(sectionId: sectionId!, slotItemIdsMap: slotItemIdsMap, completionHandler: { resultCode in
            self.didDeleteSelectedItems(resultCode: resultCode)
        })
    }
    
    override func otherActionWithSelectedItems() {
        selectedIndexPaths = tableView.indexPathsForSelectedRows
        multiInputIndex = 0
        multiInputArgs.removeAll()
        popAndAddToMultiInputArgsFromSelectedItems()
    }
    
    func setSortOrder() {
        let userDefaults = UserDefaults.standard
        
        switch userDefaults.integer(forKey: PreferenceKeyValues.frequentlyInputSortOrder) {
        case 0:
            sortProperty = "sortOrder"
            sortAscending = true
        case 1:
            sortProperty = "useCount"
            sortAscending = false
        case 2:
            sortProperty = "lastUseTime"
            sortAscending = false
        default:
            break
        }
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> FrequentItem {
        if sectionTitles.count == 0 {
            return frequentItems![indexPath.row]
        }
        
        var count = 0
        
        for i in 0..<indexPath.section {
            count += sectionDataCounts[i]
        }
        
        return frequentItems![count + indexPath.row]
    }
    
    func filtering() {
        let userDefaults = UserDefaults.standard
        let showSlotNumbers = userDefaults.object(forKey: PreferenceKeyValues.showSlotNumbers) as? [Int]
        
        if showSlotNumbers != nil && (showSlotNumbers?.count)! < 3 {
            frequentItems = frequentItems?.filter("slotNumber IN %@", showSlotNumbers!)
        }
        if let pks = searchedItems {
            frequentItems = frequentItems?.filter("pk IN %@", pks)
        }
        frequentItems = frequentItems?.sorted(byProperty: "slotNumber", ascending: true).sorted(byProperty: sortProperty!, ascending: sortAscending!)
        frequentItemsNotificationToken?.stop()
        startNotificationToken()
    }
    
    func send(_ sender: UIButton) {
        let indexPath = IndexPath.init(row: sender.tag & 0xFFFF, section: sender.tag >> 16)
        let item = itemAtIndexPath(indexPath)

        if item.money < WhooingKeyValues.epsilon || item.leftAccountType.isEmpty || item.rightAccountType.isEmpty {
            let viewController = parent as! FrequentlyInputViewController
            
            viewController.frequentItem = item
            parent?.performSegue(withIdentifier: "send", sender: nil)
        } else {
            inputEntry(item.slotNumber, itemId: item.itemId, itemTitle: item.title, money: String(item.money), leftAccountType: item.leftAccountType, leftAccountId: item.leftAccountId, rightAccountType: item.rightAccountType, rightAccountId: item.rightAccountId, memo: "")
        }
    }
    
    func inputEntry(_ slotNumber: Int, itemId: String, itemTitle: String, money: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, memo: String) {
        let params = [WhooingKeyValues.itemId: itemId,
                      WhooingKeyValues.sectionId: sectionId!,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money,
                      WhooingKeyValues.memo: memo]

        inputEntry(slotNumber, params: params)
    }
    
    func inputEntry(_ slotNumber: Int, params: [String: String], duplicateCheck: Bool = true, method: String = "POST") {
        var mutableParams = params
        var prevEntries: Results<Entry>? = nil
        
        if duplicateCheck {
            mutableParams[WhooingKeyValues.entryDate] = entryDateFormat.string(from: Date.init())
            prevEntries = DataUtility.duplicateEntries(with: try! Realm(), args: mutableParams)
        }
        if let entries = prevEntries, entries.count > 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("병합하기", comment: "병합하기"), message: NSLocalizedString("최근 내역중에 같은 내용으로 입력된 항목이 있습니다. 금액을 더해서 하나의 항목으로 병합할까요?", comment: "병합하기"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("병합하기", comment: "병합하기"), style: .default, handler: { action in
                if entries.count == 1 {
                    let entry = entries.first!
                    let money = Double(mutableParams[WhooingKeyValues.money]!)!
                    
                    mutableParams[WhooingKeyValues.money] = String(money + entry.money)
                    mutableParams[WhooingKeyValues.entryId] = String(entry.entryId)
                    self.inputEntry(slotNumber, params: mutableParams, duplicateCheck: false, method: "PUT")
                } else {
                    let parentViewController = self.parent as! FrequentlyInputViewController
                    
                    parentViewController.mergeArguments = mutableParams
                    parentViewController.performSegue(withIdentifier: "merge", sender: nil)
                }
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("새 항목으로 입력", comment: "새 항목으로 입력"), style: .destructive, handler: { action in
                self.inputEntry(slotNumber, params: mutableParams, duplicateCheck: false)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            let itemId = params[WhooingKeyValues.itemId]!
            let sectionId = params[WhooingKeyValues.sectionId]!
            let completionHandler: (Int) -> Void = { resultCode in
                objc_sync_enter(self)
                
                let sectionId = params[WhooingKeyValues.sectionId]!
                var itemIds = self.progressingItemIds[sectionId]!
                let index = itemIds.index(of: String(slotNumber) + "|" + params[WhooingKeyValues.itemId]!)!
                
                itemIds.removeSubrange(index...index)
                self.progressingItemIds[sectionId] = itemIds
                objc_sync_exit(self)
                mutableParams[WhooingKeyValues.itemId] = itemId
                self.entryInputed(resultCode, slotNumber: slotNumber, params: mutableParams, method: method)
            }
            
            mutableParams.removeValue(forKey: WhooingKeyValues.itemId)
            objc_sync_enter(self)
            if progressingItemIds[sectionId] != nil {
                progressingItemIds[sectionId]?.append(String(slotNumber) + "|" + itemId)
            } else {
                progressingItemIds[sectionId] = [String(slotNumber) + "|" + itemId]
            }
            objc_sync_exit(self)
            tableView.reloadData()
            
            switch method {
            case "POST":
                NetworkUtility.postEntry(params: mutableParams, slotNumber: slotNumber, frequentItemId: itemId, completionHandler: completionHandler)
            case "PUT":
                NetworkUtility.putEntry(params: mutableParams, completionHandler: completionHandler)
            default:
                break
            }
        }
    }
    
    func entryInputed(_ resultCode: Int, slotNumber: Int, params: [String: String], method: String) {
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("거래 입력 실패", comment: "거래 입력 실패"), message: String.init(format: NSLocalizedString("[%1$@] 거래를 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 입력 실패"), params[WhooingKeyValues.itemTitle]!), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.inputEntry(slotNumber, params: params, duplicateCheck: false, method: method)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            let _ = NetworkUtility.checkResultCodeWithAlert(resultCode)
        }
        tableView.reloadData()
    }
    
    func popAndAddToMultiInputArgsFromSelectedItems() {
        while multiInputIndex < selectedIndexPaths!.count {
            let frequentItem = itemAtIndexPath(selectedIndexPaths![multiInputIndex])
            let money = frequentItem.money
            let leftAccountType = frequentItem.leftAccountType
            let rightAccountType = frequentItem.rightAccountType
            
            multiInputIndex += 1
            if money < WhooingKeyValues.epsilon || leftAccountType.isEmpty || rightAccountType.isEmpty {
                let viewController = parent as! FrequentlyInputViewController
                
                viewController.frequentItem = frequentItem
                frequentItemsNotificationToken?.stop()
                parent?.performSegue(withIdentifier: "send", sender: nil)
                
                return
            } else {
                multiInputArgs.append([WhooingKeyValues.itemId: frequentItem.itemId,
                                       WhooingKeyValues.sectionId: sectionId!,
                                       WhooingKeyValues.leftAccountType: leftAccountType,
                                       WhooingKeyValues.leftAccountId: frequentItem.leftAccountId,
                                       WhooingKeyValues.rightAccountType: rightAccountType,
                                       WhooingKeyValues.rightAccountId: frequentItem.rightAccountId,
                                       WhooingKeyValues.itemTitle: frequentItem.title,
                                       WhooingKeyValues.money: String(money),
                                       "slotNumber": String(frequentItem.slotNumber),
                                       WhooingKeyValues.memo: ""])
            }
        }
        for args in multiInputArgs {
            var newArgs = args
            let slotNumber = Int(newArgs["slotNumber"]!)
            
            newArgs.removeValue(forKey: "slotNumber")
            inputEntry(slotNumber!, params: newArgs)
        }
        
        let parentViewController = parent as! WhooLiteTabBarItemBaseViewController
        
        parentViewController.cancelTouched(parentViewController.cancelButton)
        tableView.reloadData()
    }
    
    func startNotificationToken() {
        frequentItemsNotificationToken = frequentItems?.addNotificationBlock({changes in
            self.refreshSections()
            self.tableView.reloadData()
        })
    }
    
    func editSend(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let button = sender.view as! UIButton
            let indexPath = IndexPath.init(row: button.tag & 0xFFFF, section: button.tag >> 16)
            let viewController = parent as! FrequentlyInputViewController
            
            viewController.frequentItem = itemAtIndexPath(indexPath)
            parent?.performSegue(withIdentifier: "send", sender: nil)
        }
    }
    
    // MARK: - UISearchResultsUpdating methods
    
    func updateSearchResults(for searchController: UISearchController) {
        backgroundSearcher?.canceled = true
        backgroundSearcher = BackgroundSearcher()
        backgroundSearcher?.search(with: sectionId!, keyword: searchController.searchBar.text!, delegate: self)
    }
    
    // MARK: - UITableViewDataSource methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! FrequentlyInputTableViewCell
        let item = itemAtIndexPath(indexPath)
        
        if cell.sendButton.allTargets.count == 0 {
            let gesture = UILongPressGestureRecognizer.init(target: self, action: #selector(editSend))
            
            cell.sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
            cell.sendButton.addGestureRecognizer(gesture)
        }
        cell.sendButton.tag = indexPath.section << 16 + indexPath.row
        if let itemIds = progressingItemIds[sectionId!] {
            cell.sendButton.isHidden = itemIds.contains(String(item.slotNumber) + "|" + item.itemId)
        } else {
            cell.sendButton.isHidden = false
        }
        cell.activityIndicator.isHidden = !cell.sendButton.isHidden
        cell.activityIndicator.startAnimating()
        
        return cell
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        if !tableView.isEditing {
            let viewController = parent as! FrequentlyInputViewController
            
            viewController.frequentItem = itemAtIndexPath(indexPath)
            parent?.performSegue(withIdentifier: "detail", sender: nil)
        }
    }
    
    // MARK: - BackgroundSearcherDelegate methods
    
    func didSearch(_ searchedItems: [String]?) {
        self.searchedItems = searchedItems
        if searchedItems != nil {
            noDataText = NSLocalizedString("검색결과가 없습니다.", comment: "검색결과 없음")
            searching = true
        } else {
            noDataText = NSLocalizedString("자주입력 거래들 항목이 없습니다. 거래내역 탭에서 항목을 만들어보세요!", comment: "데이터 없음")
            searching = false
        }
        self.frequentItems = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", self.sectionId!)
        self.filtering()
        if let noDataView = self.tableView.backgroundView as? NoDataView {
            if let searchKeyword = searchController?.searchBar.text, !searchKeyword.isEmpty {
                noDataView.textLabelConstant.constant = 0
            } else {
                noDataView.textLabelConstant.constant = -20
            }
        }
    }
    
    // MARK: - FrequentlyInputDetailTableViewControllerDelegate methods
    
    func didCompleteEntry(_ slotNumber: Int, itemId: String, itemTitle: String, money: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, memo: String) {
        if tableView.isEditing {
            multiInputArgs.append([WhooingKeyValues.itemId: itemId,
                                   WhooingKeyValues.sectionId: sectionId!,
                                   WhooingKeyValues.leftAccountType: leftAccountType,
                                   WhooingKeyValues.leftAccountId: leftAccountId,
                                   WhooingKeyValues.rightAccountType: rightAccountType,
                                   WhooingKeyValues.rightAccountId: rightAccountId,
                                   WhooingKeyValues.itemTitle: itemTitle,
                                   WhooingKeyValues.money: money,
                                   "slotNumber": String(slotNumber),
                                   WhooingKeyValues.memo: memo])
            startNotificationToken()
            popAndAddToMultiInputArgsFromSelectedItems()
        } else {
            inputEntry(slotNumber, itemId: itemId, itemTitle: itemTitle, money: money, leftAccountType: leftAccountType, leftAccountId: leftAccountId, rightAccountType: rightAccountType, rightAccountId: rightAccountId, memo: memo)
        }
    }
    
    func didNotCompleteEntry() {
        startNotificationToken()
        if selectedIndexPaths != nil {
            popAndAddToMultiInputArgsFromSelectedItems()
        }
    }
    
    // MARK: - Notification handler methods
    
    func settingChanged(notification: Notification) {
        if notification.name.rawValue == Notifications.frequentlyInputSortOrderChanged {
            setSortOrder()
        }
        self.frequentItems = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", self.sectionId!)
        self.filtering()
    }
    
    override func logout() {
        super.logout()
        frequentItemsNotificationToken?.stop()
    }
}
