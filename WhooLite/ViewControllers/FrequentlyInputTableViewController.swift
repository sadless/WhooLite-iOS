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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
                    
                    for key in frequentItems.keys {
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
        
    }
}
