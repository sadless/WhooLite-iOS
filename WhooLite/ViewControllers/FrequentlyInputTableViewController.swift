//
//  FrequentlyInputTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class FrequentlyInputTableViewController: WhooLiteTabBarItemBaseTableViewController, UISearchResultsUpdating {    
    var searchedTitles: [String]?
    var allFrequentItems: Results<FrequentItem>?
    var frequentItems: Results<FrequentItem>?
    var frequentItemsNotificationToken: NotificationToken?
    var sortProperty: String?
    var sortAscending: Bool?
    var searchController: UISearchController?
    var progressingItemIds = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        receiveFailedText = NSLocalizedString("자주입력 거래들 항목을 가져오지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "실패")
        noDataText = NSLocalizedString("자주입력 거래들 항목이 없습니다. 거래내역 탭에서 항목을 만들어보세요!", comment: "데이터 없음")
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
    }
    
    deinit {
        frequentItemsNotificationToken?.stop()
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
        var url = NSURL.init(string: NetworkUtility.frequentItemsUrl)!
        
        url = url.URLByAppendingPathExtension("json_array")
        
        let urlComponents = NSURLComponents.init(string: url.absoluteString)!
        
        urlComponents.queryItems = [NSURLQueryItem.init(name: WhooingKeyValues.sectionId, value: sectionId!)]
        NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(urlComponents.URL!, method: "GET", params: nil), completionHandler: {data, response, error in
            if error == nil {
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                let resultCode = json[WhooingKeyValues.code] as! Int
                
                if resultCode == WhooingKeyValues.success {
                    let frequentItems = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    var objects = [FrequentItem]()
                    var primaryKeys = [String]()
                    var i = 0
                    var slotNumber = 1
                    
                    for key in frequentItems.keys.sort() {
                        let itemsInSlot = frequentItems[key] as! [[String: AnyObject]]
                        
                        for frequentItem in itemsInSlot {
                            let itemId = frequentItem[WhooingKeyValues.itemId] as! String
                            let object = FrequentItem()
                            let oldObject = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", self.sectionId!, slotNumber, itemId).first
                            
                            object.sectionId = self.sectionId!
                            object.slotNumber = slotNumber
                            object.itemId = itemId
                            object.title = frequentItem[WhooingKeyValues.itemTitle] as! String
                            object.money = frequentItem[WhooingKeyValues.money] as! Double
                            object.leftAccountType = frequentItem[WhooingKeyValues.leftAccountType] as! String
                            object.leftAccountId = frequentItem[WhooingKeyValues.leftAccountId] as! String
                            object.rightAccountType = frequentItem[WhooingKeyValues.rightAccountType] as! String
                            object.rightAccountId = frequentItem[WhooingKeyValues.rightAccountId] as! String
                            if let old = oldObject {
                                object.useCount = old.useCount
                                object.lastUseTime = old.lastUseTime
                                object.searchKeyword = old.searchKeyword
                            }
                            object.sortOrder = i
                            object.composePrimaryKey()
                            objects.append(object)
                            i += 1
                            primaryKeys.append(object.pk)
                        }
                        slotNumber += 1
                    }
                    try! realm.write({
                        realm.add(objects, update: true)
                        realm.delete(realm.objects(FrequentItem.self).filter("sectionId == %@ AND NOT (pk IN %@)", self.sectionId!, primaryKeys))
                    })
                }
                self.mainDataReceived(resultCode)
            } else {
                self.mainDataReceived(-1)
            }
        }).resume()
    }
    
    override func sectionChanged() {
        allFrequentItems = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", sectionId!)
        filtering()
        frequentItemsNotificationToken?.stop()
        frequentItemsNotificationToken = allFrequentItems?.addNotificationBlock({changes in
            switch changes {
            case .Initial:
                break
            default:
                self.filtering()
            }
        })
    }
    
    override func refreshSections() {
        sectionTitles.removeAll()
        sectionDataCounts.removeAll()
        
        var needSection = sectionId != nil
        
        if needSection {
            needSection = frequentItems?.count > 0
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
    
    override func dataTitle(indexPath: NSIndexPath) -> String {
        return itemAtIndexPath(indexPath).title
    }
    
    override func dataMoney(indexPath: NSIndexPath) -> Double {
        return itemAtIndexPath(indexPath).money
    }
    
    override func dataLeftAccountType(indexPath: NSIndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountType
    }
    
    override func dataLeftAccountId(indexPath: NSIndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountId
    }
    
    override func dataRightAccountType(indexPath: NSIndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountType
    }
    
    override func dataRightAccountId(indexPath: NSIndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountId
    }
    
    func setSortOrder() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        switch userDefaults.integerForKey(PreferenceKeys.frequentlyInputSortOrder) {
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
    
    func itemAtIndexPath(indexPath: NSIndexPath) -> FrequentItem {
        if sectionTitles.count == 0 {
            return frequentItems![indexPath.row]
        }
        
        var count = 0
        
        for i in 0..<indexPath.section {
            count += sectionDataCounts[i]
        }
        
        return frequentItems![count + indexPath.row]
    }
    
    func search(searchKeyword: String) {
        if !searchKeyword.isEmpty {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            let showSlotNumbers = userDefaults.objectForKey(PreferenceKeys.showSlotNumbers) as? [Int]
            let items = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", sectionId!)
            var titles = [String]()

            if showSlotNumbers != nil && showSlotNumbers?.count < 3 {
                for slotNumber in showSlotNumbers! {
                    items.filter("slotNumber == %d", slotNumber)
                }
            }
            for item in items {
                let originalTitle = item.title
                let trimmedTitle = originalTitle.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                
                if SoundSearcher.matchString(trimmedTitle, search: searchKeyword) {
                    titles.append(originalTitle)
                } else if !item.searchKeyword.isEmpty {
                    let trimmedKeyword = item.searchKeyword.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    
                    if SoundSearcher.matchString(trimmedKeyword, search: searchKeyword) {
                        titles.append(originalTitle)
                    }
                }
            }
            searchedTitles = titles
            noDataText = NSLocalizedString("검색결과가 없습니다.", comment: "검색결과 없음")
            searching = true
        } else {
            searchedTitles = nil
            noDataText = NSLocalizedString("자주입력 거래들 항목이 없습니다. 거래내역 탭에서 항목을 만들어보세요!", comment: "데이터 없음")
            searching = false
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.filtering()
            
            if let noDataView = self.tableView.backgroundView as? NoDataView {
                if !searchKeyword.isEmpty {
                    noDataView.textLabelConstant.constant = 0
                } else {
                    noDataView.textLabelConstant.constant = -20
                }
            }
        })
    }
    
    func filtering() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let showSlotNumbers = userDefaults.objectForKey(PreferenceKeys.showSlotNumbers) as? [Int]
        
        if showSlotNumbers != nil && showSlotNumbers?.count < 3 {
            frequentItems = allFrequentItems?.filter("slotNumber IN %@", showSlotNumbers!)
        } else {
            frequentItems = allFrequentItems
        }
        if let titles = searchedTitles {
            frequentItems = frequentItems?.filter("title IN %@", titles)
        }
        frequentItems = frequentItems?.sorted("slotNumber", ascending: true).sorted(sortProperty!, ascending: sortAscending!)
        tableView.reloadData()
    }
    
    func send(sender: UIButton) {
        let indexPath = NSIndexPath.init(forRow: sender.tag & 0xFFFF, inSection: sender.tag >> 16)
        let item = itemAtIndexPath(indexPath)

        if item.money < WhooingKeyValues.epsilon || item.leftAccountType.isEmpty || item.rightAccountType.isEmpty {
            
        } else {
            inputEntry(item.slotNumber, itemId: item.itemId, itemTitle: item.title, money: String(item.money), leftAccountType: item.leftAccountType, leftAccountId: item.leftAccountId, rightAccountType: item.rightAccountType, rightAccountId: item.rightAccountId, memo: "")
        }
    }
    
    func inputEntry(slotNumber: Int, itemId: String, itemTitle: String, money: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, memo: String) {
        var params = [WhooingKeyValues.itemId: itemId,
                      WhooingKeyValues.sectionId: sectionId!,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money]

        if !memo.isEmpty {
            params[WhooingKeyValues.memo] = memo
        }
        inputEntry(slotNumber, params: params)
    }
    
    func inputEntry(slotNumber: Int, params: [String: String]) {
        let itemId = params[WhooingKeyValues.itemId]!
        let sectionId = params[WhooingKeyValues.sectionId]!
        
        objc_sync_enter(self)
        if progressingItemIds[sectionId] != nil {
            progressingItemIds[sectionId]?.append(String(slotNumber) + "|" + itemId)
        } else {
            progressingItemIds[sectionId] = [String(slotNumber) + "|" + itemId]
        }
        objc_sync_exit(self)
        tableView.reloadData()
        
        var url = NSURL.init(string: NetworkUtility.entriesUrl)!
        
        url = url.URLByAppendingPathExtension("json_array")
        NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(url, method: "POST", params: params), completionHandler: {(data, response, error) in
            var resultCode = -1
            
            if error == nil {
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let resultItem = (json[WhooingKeyValues.result] as! [[String: AnyObject]])[0]
                    let realm = try! Realm()
                    
                    try! realm.write {
                        let frequentItem = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", self.sectionId!, slotNumber, itemId).first
                        
                        if let item = frequentItem {
                            item.useCount += 1
                            item.lastUseTime = NSDate.init().timeIntervalSince1970
                        }
                        realm.add(DataUtility.createEntryFromJson(resultItem, sectionId: self.sectionId!), update: true)
                    }
                }
            }
            objc_sync_enter(self)
            
            let sectionId = params[WhooingKeyValues.sectionId]!
            var itemIds = self.progressingItemIds[sectionId]!
            let index = itemIds.indexOf(String(slotNumber) + "|" + params[WhooingKeyValues.itemId]!)!
            
            itemIds.removeRange(index...index)
            self.progressingItemIds[sectionId] = itemIds
            objc_sync_exit(self)
            dispatch_async(dispatch_get_main_queue(), {
                self.entryInputed(resultCode, slotNumber: slotNumber, params: params)
            })
        }).resume()
    }
    
    func entryInputed(resultCode: Int, slotNumber: Int, params: [String: String]) {
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("거래 입력 실패", comment: "거래 입력 실패"), message: String.init(format: NSLocalizedString("[%1$@] 거래를 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 입력 실패"), params[WhooingKeyValues.itemTitle]!), preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .Default, handler: {action in
                self.inputEntry(slotNumber, params: params)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .Cancel, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - UISearchResultsUpdating methods
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        performSelectorInBackground(#selector(search), withObject: searchController.searchBar.text!)
    }
    
    // MARK: - UITableViewDataSource methods
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! FrequentlyInputTableViewCell
        let item = itemAtIndexPath(indexPath)
        
        if cell.sendButton.allTargets().count == 0 {
            cell.sendButton.addTarget(self, action: #selector(send), forControlEvents: .TouchUpInside)
        }
        cell.sendButton.tag = indexPath.section << 16 + indexPath.row
        if let itemIds = progressingItemIds[sectionId!] {
            cell.sendButton.hidden = itemIds.contains(String(item.slotNumber) + "|" + item.itemId)
        } else {
            cell.sendButton.hidden = false
        }
        cell.activityIndicator.hidden = !cell.sendButton.hidden
        cell.activityIndicator.startAnimating()
        
        return cell
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let viewController = parentViewController as! FrequentlyInputViewController
        
        viewController.frequentItem = itemAtIndexPath(indexPath)
        parentViewController?.performSegueWithIdentifier("detail", sender: nil)
    }
}
