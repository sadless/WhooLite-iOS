//
//  DataUtility.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 31..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class DataUtility: NSObject {
    static func createEntryFromJson(_ entry: [String: AnyObject], sectionId: String) -> Entry {
        let object = Entry()
        
        object.sectionId = sectionId
        object.entryId = (entry[WhooingKeyValues.entryId] as! NSNumber).int64Value
        setEntryFromJson(object, entry: entry)
        object.composePrimaryKey()
        
        return object
    }
    
    static func setEntryFromJson(_ object: Entry, entry: [String: AnyObject]) {
        object.title = entry[WhooingKeyValues.itemTitle] as! String
        if let number = entry[WhooingKeyValues.money] as? NSNumber {
            object.money = number.doubleValue
        } else {
            object.money = Double(entry[WhooingKeyValues.money] as! String)!
        }
        object.leftAccountType = entry[WhooingKeyValues.leftAccountType] as! String
        object.leftAccountId = entry[WhooingKeyValues.leftAccountId] as! String
        object.rightAccountType = entry[WhooingKeyValues.rightAccountType] as! String
        object.rightAccountId = entry[WhooingKeyValues.rightAccountId] as! String
        object.memo = entry[WhooingKeyValues.memo] as! String
        object.entryDate = Double(entry[WhooingKeyValues.entryDate] as! String)!
    }
    
    static func dateFormat(from whooingDateFormat: String) -> DateFormatter {
        var dateFormatString = ""
        
        for i in 0..<whooingDateFormat.characters.count {
            if i > 0 {
                dateFormatString += "-"
            }
            
            let index = whooingDateFormat.index(whooingDateFormat.startIndex, offsetBy: i)
            
            switch whooingDateFormat[index...index] {
            case "Y":
                dateFormatString += "yyyy"
            case "M":
                dateFormatString += "MM"
            case "D":
                dateFormatString += "dd"
            default:
                break
            }
        }
        dateFormatString += " E"
        
        let dateFormat = DateFormatter.init()
        
        dateFormat.dateFormat = dateFormatString
        
        return dateFormat
    }
    
    static func createFrequentItem(fromJson frequentItem: [String: AnyObject], sectionId: String, slotNumber: Int, sortOrder: Int, searchKeyword: String, useCount: Int, lastUseTime: Double) -> FrequentItem {
        let object = FrequentItem()
        
        object.sectionId = sectionId
        object.slotNumber = slotNumber
        object.itemId = frequentItem[WhooingKeyValues.itemId] as! String
        object.sortOrder = sortOrder
        object.searchKeyword = searchKeyword
        object.useCount = useCount
        object.lastUseTime = lastUseTime
        setFrequentItem(fromJson: object, frequentItem: frequentItem)
        object.composePrimaryKey()
        
        return object
    }
    
    static func setFrequentItem(fromJson object: FrequentItem, frequentItem: [String: AnyObject]) {
        object.title = frequentItem[WhooingKeyValues.itemTitle] as! String
        object.money = frequentItem[WhooingKeyValues.money] as! Double
        object.leftAccountType = frequentItem[WhooingKeyValues.leftAccountType] as! String
        object.leftAccountId = frequentItem[WhooingKeyValues.leftAccountId] as! String
        object.rightAccountType = frequentItem[WhooingKeyValues.rightAccountType] as! String
        object.rightAccountId = frequentItem[WhooingKeyValues.rightAccountId] as! String
    }
    
    static func duplicateEntries(with realm: Realm, args: [String: String]) -> Results<Entry> {
        var memo = args[WhooingKeyValues.memo]
        let entryId = args[WhooingKeyValues.entryId]
        let entryDate = Int(args[WhooingKeyValues.entryDate]!)!
        
        if memo == nil {
            memo = ""
        }
        
        var entries = realm.objects(Entry.self).filter("sectionId == %@ AND entryDate >= %d AND entryDate < %d AND title == %@ AND leftAccountType == %@ AND leftAccountId == %@ AND rightAccountType == %@ AND rightAccountId == %@ AND memo == %@", args[WhooingKeyValues.sectionId]!, entryDate, entryDate + 1, args[WhooingKeyValues.itemTitle]!, args[WhooingKeyValues.leftAccountType]!, args[WhooingKeyValues.leftAccountId]!, args[WhooingKeyValues.rightAccountType]!, args[WhooingKeyValues.rightAccountId]!, memo!)
        
        if entryId != nil {
            entries = entries.filter("entryId != %lld", Int64(entryId!)!)
        }
        
        return entries
    }
    
    static func duplicateEntries(with realm: Realm, sectionId: String, entryDate: String, itemTitle: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, memo: String) -> Results<Entry> {
        let params = [WhooingKeyValues.sectionId: sectionId,
                      WhooingKeyValues.itemTitle: itemTitle,
                      WhooingKeyValues.leftAccountType: leftAccountType,
                      WhooingKeyValues.leftAccountId: leftAccountId,
                      WhooingKeyValues.rightAccountType: rightAccountType,
                      WhooingKeyValues.rightAccountId: rightAccountId,
                      WhooingKeyValues.memo: memo,
                      WhooingKeyValues.entryDate: entryDate]
        
        return duplicateEntries(with: realm, args: params)
    }
}
