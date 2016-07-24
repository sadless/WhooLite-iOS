//
//  FrequentlyInputTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class FrequentlyInputTableViewController: WhooLiteTabBarItemBaseTableViewController {
    let frequentItemsUrl = "https://whooing.com/api/frequent_items"
    
    var searchedTitles: [String]?
    var frequentItems: Results<FrequentItem>?
    var frequentItemsNotificationToken: NotificationToken?
    var sortProperty: String?
    var sortAscending: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        receiveFailedText = NSLocalizedString("자주입력 거래들 항목을 가져오지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "실패")
        noDataText = NSLocalizedString("자주입력 거래들 항목이 없습니다. 거래내역 탭에서 항목을 만들어보세요!", comment: "데이터 없음")
        setSortOrder()
        if sectionId != nil {
            sectionChanged()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Instance methods
    
    override func refreshMainData() {
        var url = NSURL.init(string: frequentItemsUrl)!
        
        url = url.URLByAppendingPathExtension("json_array")
        
        let urlComponents = NSURLComponents.init(string: url.absoluteString)!
        
        urlComponents.queryItems = [NSURLQueryItem.init(name: WhooingKeyValues.sectionId, value: sectionId!)]
        NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(urlComponents.URL!, method: "GET", params: nil), completionHandler: {data, response, error in
            if let resultData = data {
                let json = try! NSJSONSerialization.JSONObjectWithData(resultData, options: []) as! [String: AnyObject]
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
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let showSlotNumbers = userDefaults.objectForKey(PreferenceKeys.showSlotNumbers) as? [Int]
        var items = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", sectionId!)
        
        if showSlotNumbers != nil && showSlotNumbers?.count < 3 {
            for slotNumber in showSlotNumbers! {
                items.filter("slotNumber == %d", slotNumber)
            }
        }
        if let titles = searchedTitles {
            items.filter("title IN %@", titles)
        }
        items = items.sorted("slotNumber", ascending: true).sorted(sortProperty!, ascending: sortAscending!)
        frequentItems = items
        frequentItemsNotificationToken?.stop()
        frequentItemsNotificationToken = frequentItems?.addNotificationBlock({changes in
            self.tableView.reloadData()
        })
    }
    
    override func refreshSections() {
        sectionTitles = [String]()
        sectionDataCounts = [Int]()
        
        var needSection = sectionId != nil
        
        if needSection {
            let realm = try! Realm()
            let items = realm.objects(FrequentItem.self).filter("sectionId == %@", sectionId!).sorted("slotNumber", ascending: true)
            
            needSection = items.count > 0
            if needSection {
                var slot = items[0].slotNumber
                var count = 0
                
                for item in items {
                    if slot == item.slotNumber {
                        count += 1
                    } else {
                        sectionTitles?.append(String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), slot))
                        sectionDataCounts?.append(count)
                        slot = item.slotNumber
                        count = 1
                    }
                }
                needSection = sectionTitles?.count > 0
                if needSection {
                    sectionTitles?.append(String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호"), slot))
                    sectionDataCounts?.append(count)
                } else {
                    sectionDataCounts?.append(items.count)
                }
            }
        }
        if !needSection {
            sectionTitles = nil
            sectionDataCounts?.append(0)
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
        if sectionTitles == nil {
            return frequentItems![indexPath.row]
        }
        
        var count = 0
        
        for i in 0..<indexPath.section {
            count += sectionDataCounts![i]
        }
        
        return frequentItems![count + indexPath.row]
    }
}
