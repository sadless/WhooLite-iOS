//
//  DataUtility.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 31..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class DataUtility: NSObject {
    static func createEntryFromJson(entry: [String: AnyObject], sectionId: String) -> Entry {
        let object = Entry()
        
        object.sectionId = sectionId
        object.entryId = (entry[WhooingKeyValues.entryId] as! NSNumber).longLongValue
        setEntryFromJson(object, entry: entry)
        object.composePrimaryKey()
        
        return object
    }
    
    static func setEntryFromJson(object: Entry, entry: [String: AnyObject]) {
        object.title = entry[WhooingKeyValues.itemTitle] as! String
        object.money = Double(entry[WhooingKeyValues.money] as! String)!
        object.leftAccountType = entry[WhooingKeyValues.leftAccountType] as! String
        object.leftAccountId = entry[WhooingKeyValues.leftAccountId] as! String
        object.rightAccountType = entry[WhooingKeyValues.rightAccountType] as! String
        object.rightAccountId = entry[WhooingKeyValues.rightAccountId] as! String
        object.memo = entry[WhooingKeyValues.memo] as! String
        object.entryDate = Double(entry[WhooingKeyValues.entryDate] as! String)!
    }
}
