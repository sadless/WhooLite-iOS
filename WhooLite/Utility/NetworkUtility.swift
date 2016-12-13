//
//  NetworkUtility.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class NetworkUtility: NSObject {
    static let sectionsUrl = "https://whooing.com/api/sections"
    static let accountsUrl = "https://whooing.com/api/accounts"
    static let frequentItemsUrl = "https://whooing.com/api/frequent_items"
    static let entriesUrl = "https://whooing.com/api/entries"
    
    static func requestForApiCall(_ url: URL, method: String, params: [String: String]?) -> URLRequest {
        let userDefaults = UserDefaults.standard
        let apiKey = String.init(format: userDefaults.object(forKey: PreferenceKeyValues.apiKeyFormat) as! String, Date.init().timeIntervalSince1970)
        var request = URLRequest.init(url: url)
        
        request.setValue(apiKey, forHTTPHeaderField: WhooingKeyValues.apiKey)
        request.httpMethod = method
        if let postParams = params {
            var urlComponents = URLComponents.init()
            var queryItems = [URLQueryItem]()
            
            for key in postParams.keys {
                queryItems.append(URLQueryItem.init(name: key, value: postParams[key]))
            }
            urlComponents.queryItems = queryItems
            request.httpBody = urlComponents.query?.data(using: String.Encoding.utf8)
        }
        
        return request
    }
    
    static func checkResultCodeWithAlert(_ code: Int) -> Bool {
        switch code {
        case 405:
            let alertController = UIAlertController.init(title: NSLocalizedString("토큰 만료됨", comment: "토큰 만료됨"), message: NSLocalizedString("인증토큰이 만료되어 다시 로그인 하셔야 합니다.", comment: "토큰 만료됨"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 로그인", comment: "다시 로그인"), style: .default, handler: { action in
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                delegate.logout()
            }))
            return false
        default:
            return true
        }
    }
    
    static func postFrequentItem(slotNumber: Int, sectionId: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, itemTitle: String, money: String, searchKeyword: String, useCount: Int = 0, lastUseTime: Double = Date.init().timeIntervalSince1970, completionHandler: @escaping (Int) -> Void) {
        let params = [WhooingKeyValues.sectionId: sectionId,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money]
        var url = URL.init(string: frequentItemsUrl)!

        url = url.appendingPathComponent("slot" + String(slotNumber) + ".json")
        URLSession.shared.dataTask(with: requestForApiCall(url, method: "POST", params: params), completionHandler: {data, response, error in
            var resultCode = -1

            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    let frequentItems = realm.objects(FrequentItem.self).sorted(byProperty: "sortOrder", ascending: false)
                    var sortOrder: Int
                    
                    if let frequentItem = frequentItems.first {
                        sortOrder = frequentItem.sortOrder + 1
                    } else {
                        sortOrder = 0
                    }
                    
                    let item = DataUtility.createFrequentItem(fromJson: resultItem, sectionId: sectionId, slotNumber: slotNumber, sortOrder: sortOrder, searchKeyword: searchKeyword, useCount: useCount, lastUseTime: lastUseTime)
                    
                    try! realm.write {
                        realm.add(item, update: true)
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completionHandler(resultCode)
            })
        }).resume()
    }
    
    static func putFrequentItem(slotNumber: Int, itemId: String, sectionId: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, itemTitle: String, money: String, searchKeyword: String, completionHandler: @escaping (Int) -> Void) {
        let params = [WhooingKeyValues.sectionId: sectionId,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money]
        var url = URL.init(string: frequentItemsUrl)!
        
        url = url.appendingPathComponent("slot" + String(slotNumber))
            .appendingPathComponent(itemId + ".json")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "PUT", params: params), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    
                    try! realm.write {
                        let item = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", sectionId, slotNumber, itemId).first
                        
                        if let i = item {
                            DataUtility.setFrequentItem(fromJson: i, frequentItem: resultItem)
                            i.searchKeyword = searchKeyword
                        }
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completionHandler(resultCode)
            })
        }).resume()
    }
    
    static func postEntry(sectionId: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, itemTitle: String, money: String, memo: String, entryDate: String?, slotNumber: Int?, frequentItemId: String?, completionHandler: @escaping (Int) -> Void) {
        var params = [WhooingKeyValues.sectionId: sectionId,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money]
        
        if let entryDate = entryDate {
            params[WhooingKeyValues.entryDate] = entryDate
        }
        
        var url = URL.init(string: entriesUrl)!
        
        url = url.appendingPathExtension("json_array")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "POST", params: params), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let resultItem = (json[WhooingKeyValues.result] as! [[String: AnyObject]])[0]
                    let realm = try! Realm()
                    
                    try! realm.write {
                        if slotNumber != nil {
                            let item = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", sectionId, slotNumber!, frequentItemId!).first
                            
                            if let item = item {
                                item.useCount += 1
                                item.lastUseTime = NSDate.init().timeIntervalSince1970
                            }
                        }
                        realm.add(DataUtility.createEntryFromJson(resultItem, sectionId: sectionId))
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completionHandler(resultCode)
            })
        }).resume()
    }
    
    static func deleteFrequentItem(slotNumber: Int, itemId: String, sectionId: String, completionHandler: @escaping (Int) -> Void) {
        var url = URL.init(string: frequentItemsUrl)!
        
        url = url.appendingPathComponent("slot" + String(slotNumber))
            .appendingPathComponent(itemId)
            .appendingPathComponent(sectionId + ".json")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "DELETE", params: nil), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let realm = try! Realm()
                    
                    try! realm.write {
                        let item = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", sectionId, slotNumber, itemId).first
                        
                        if let item = item {
                            realm.delete(item)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }).resume()
    }
    
    static func getFrequentItems(sectionId: String, completionHandler: @escaping (Int) -> Void) {
        var url = URL.init(string: NetworkUtility.frequentItemsUrl)!
        
        url = url.appendingPathExtension("json_array")
        
        var urlComponents = URLComponents.init(string: url.absoluteString)!
        
        urlComponents.queryItems = [URLQueryItem.init(name: WhooingKeyValues.sectionId, value: sectionId)]
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(urlComponents.url!, method: "GET", params: nil), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let frequentItems = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    var objects = [FrequentItem]()
                    var primaryKeys = [String]()
                    var i = 0
                    var slotNumber = 1
                    
                    for key in frequentItems.keys.sorted() {
                        let itemsInSlot = frequentItems[key] as! [[String: AnyObject]]
                        
                        for frequentItem in itemsInSlot {
                            let itemId = frequentItem[WhooingKeyValues.itemId] as! String
                            let oldObject = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", sectionId, slotNumber, itemId).first
                            var searchKeyword = ""
                            var lastUseTime = 0.0
                            var useCount = 0
                            
                            if let old = oldObject {
                                useCount = old.useCount
                                lastUseTime = old.lastUseTime
                                searchKeyword = old.searchKeyword
                            }
                            
                            let object = DataUtility.createFrequentItem(fromJson: frequentItem, sectionId: sectionId, slotNumber: slotNumber, sortOrder: i, searchKeyword: searchKeyword, useCount: useCount, lastUseTime: lastUseTime)
                            
                            objects.append(object)
                            i += 1
                            primaryKeys.append(object.pk)
                        }
                        slotNumber += 1
                    }
                    try! realm.write({
                        realm.add(objects, update: true)
                        realm.delete(realm.objects(FrequentItem.self).filter("sectionId == %@ AND NOT (pk IN %@)", sectionId, primaryKeys))
                    })
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }).resume()
    }
    
    static func deleteFrequentItems(sectionId: String, slotItemIdsMap: [Int: [String]], completionHandler: @escaping (Int) -> Void) {
        DispatchQueue.global().async {
            var resultCode = -1
            var failed = false
            
            for slotNumber in slotItemIdsMap.keys {
                let itemIds = slotItemIdsMap[slotNumber]!
                var url = URL.init(string: NetworkUtility.frequentItemsUrl)
                let itemIdsPath = itemIds.joined(separator: ",")
                
                url = url?.appendingPathComponent("slot" + String(slotNumber))
                    .appendingPathComponent(itemIdsPath, isDirectory: true)
                    .appendingPathComponent(sectionId + ".json")
                
                let semaphore = DispatchSemaphore.init(value: 0)
                
                URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url!, method: "DELETE", params: nil), completionHandler: { data, response, error in
                    if error == nil {
                        let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                        
                        resultCode = json[WhooingKeyValues.code] as! Int
                        if resultCode == WhooingKeyValues.success {
                            let realm = try! Realm()
                            let items = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId IN %@", sectionId, slotNumber, itemIds)
                            
                            if items.count > 0 {
                                try! realm.write {
                                    realm.delete(items)
                                }
                            }
                        } else {
                            failed = true
                        }
                    } else {
                        failed = true
                    }
                    semaphore.signal()
                }).resume()
                semaphore.wait()
                if failed {
                    break
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }
    }
    
    static func postEntry(params: [String: String], slotNumber: Int?, frequentItemId: String?, completionHandler: @escaping (Int) -> Void) {
        postEntry(sectionId: params[WhooingKeyValues.sectionId]!, leftAccountType: params[WhooingKeyValues.leftAccountType]!, leftAccountId: params[WhooingKeyValues.leftAccountId]!, rightAccountType: params[WhooingKeyValues.rightAccountType]!, rightAccountId: params[WhooingKeyValues.rightAccountId]!, itemTitle: params[WhooingKeyValues.itemTitle]!, money: params[WhooingKeyValues.money]!, memo: params[WhooingKeyValues.memo]!, entryDate: params[WhooingKeyValues.entryDate], slotNumber: slotNumber, frequentItemId: frequentItemId, completionHandler: completionHandler)
    }
    
    static func putEntry(sectionId: String, entryId: Int64, entryDate: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, itemTitle: String, money: String, memo: String, completionHandler: @escaping (Int) -> Void) {
        let params = [WhooingKeyValues.sectionId: sectionId,
                      WhooingKeyValues.entryDate: entryDate,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.money: money,
                      WhooingKeyValues.memo: memo]
        var url = URL.init(string: NetworkUtility.entriesUrl)!
        
        url = url.appendingPathComponent(String(entryId) + ".json")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "PUT", params: params), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    
                    try! realm.write {
                        let editedEntry = realm.objects(Entry.self).filter("sectionId == %@ && entryId == %lld", sectionId, entryId).first
                        
                        if let entry = editedEntry {
                            DataUtility.setEntryFromJson(entry, entry: resultItem)
                        }
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completionHandler(resultCode)
            })
        }).resume()
    }
    
    static func putEntry(params: [String: String], completionHandler: @escaping (Int) -> Void) {
        putEntry(sectionId: params[WhooingKeyValues.sectionId]!, entryId: Int64(params[WhooingKeyValues.entryId]!)!, entryDate: params[WhooingKeyValues.entryDate]!, leftAccountType: params[WhooingKeyValues.leftAccountType]!, leftAccountId: params[WhooingKeyValues.leftAccountId]!, rightAccountType: params[WhooingKeyValues.rightAccountType]!, rightAccountId: params[WhooingKeyValues.rightAccountId]!, itemTitle: params[WhooingKeyValues.itemTitle]!, money: params[WhooingKeyValues.money]!, memo: params[WhooingKeyValues.memo]!, completionHandler: completionHandler)
    }
    
    static func deleteEntry(sectionId: String, entryId: Int64, completionHandler: @escaping (Int) -> Void) {
        var url = URL.init(string: NetworkUtility.entriesUrl)!
        
        url = url.appendingPathComponent(String(entryId) + ".json")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "DELETE", params: nil), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let realm = try! Realm()
                    
                    try! realm.write {
                        let deletedEntry = realm.objects(Entry.self).filter("sectionId == %@ && entryId == %lld", sectionId, entryId).first
                        
                        if let entry = deletedEntry {
                            realm.delete(entry)
                        }
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                completionHandler(resultCode)
            })
        }).resume()
    }
    
    static func getEntries(sectionId: String, completionHandler: @escaping (Int) -> Void) {
        var url = URL.init(string: NetworkUtility.entriesUrl)!
        
        url = url.appendingPathComponent("latest.json")
        
        var urlComponents = URLComponents.init(string: url.absoluteString)!
        
        urlComponents.queryItems = [URLQueryItem.init(name: WhooingKeyValues.sectionId, value: sectionId)]
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(urlComponents.url!, method: "GET", params: nil), completionHandler: {data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let entries = json[WhooingKeyValues.result] as! [[String: AnyObject]]
                    let realm = try! Realm()
                    var objects = [Entry]()
                    var primaryKeys = [String]()
                    
                    for entry in entries {
                        let object = DataUtility.createEntryFromJson(entry, sectionId: sectionId)
                        
                        objects.append(object)
                        primaryKeys.append(object.pk)
                    }
                    try! realm.write({
                        realm.add(objects, update: true)
                        realm.delete(realm.objects(Entry.self).filter("sectionId == %@ AND NOT (pk IN %@)", sectionId, primaryKeys))
                    })
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }).resume()
    }
    
    static func deleteEntries(sectionId: String, entryIds: [Int64], completionHandler: @escaping (Int) -> Void) {
        var entryIdsPath = ""
        
        for entryId in entryIds {
            if entryIdsPath.isEmpty {
                entryIdsPath = String(entryId)
            } else {
                entryIdsPath += "," + String(entryId)
            }
        }
        
        var url = URL.init(string: NetworkUtility.entriesUrl)!
        
        url = url.appendingPathComponent(entryIdsPath, isDirectory: true)
            .appendingPathExtension("json")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "DELETE", params: nil), completionHandler: { data, response, error in
            var resultCode = -1
            
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                
                resultCode = json[WhooingKeyValues.code] as! Int
                if resultCode == WhooingKeyValues.success {
                    let realm = try! Realm()
                    let entries = realm.objects(Entry.self).filter("sectionId == %@ AND entryId IN %@", sectionId, entryIds)
                    
                    if entries.count > 0 {
                        try! realm.write {
                            realm.delete(entries)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }).resume()
    }
    
    static func postFrequentItems(sectionId: String, slotNumber: Int, params: [[String: String]], completionHandler: @escaping (Int) -> Void) {
        DispatchQueue.global().async {
            var resultCode = -1
            var failed = false
            var mutableParams = params
            
            while mutableParams.count > 0 {
                let semaphore = DispatchSemaphore.init(value: 0)
                let param = mutableParams[0]
                var url = URL.init(string: NetworkUtility.frequentItemsUrl)!
                
                url = url.appendingPathComponent("slot" + String(slotNumber) + ".json")
                URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "POST", params: param), completionHandler: {data, response, error in
                    if error == nil {
                        let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                        
                        resultCode = json[WhooingKeyValues.code] as! Int
                        if resultCode == WhooingKeyValues.success {
                            let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                            let realm = try! Realm()
                            let frequentItems = realm.objects(FrequentItem.self).sorted(byProperty: "sortOrder", ascending: false)
                            var sortOrder: Int
                            
                            if let frequentItem = frequentItems.first {
                                sortOrder = frequentItem.sortOrder + 1
                            } else {
                                sortOrder = 0
                            }
                            
                            let item = DataUtility.createFrequentItem(fromJson: resultItem, sectionId: sectionId, slotNumber: slotNumber, sortOrder: sortOrder, searchKeyword: "", useCount: 0, lastUseTime: 0.0)
                            
                            try! realm.write {
                                realm.add(item, update: true)
                            }
                        } else {
                            failed = true
                        }
                        mutableParams.remove(at: 0)
                    } else {
                        failed = true
                    }
                    semaphore.signal()
                }).resume()
                semaphore.wait()
                if failed {
                    break
                }
            }
            DispatchQueue.main.async {
                completionHandler(resultCode)
            }
        }
    }
}
