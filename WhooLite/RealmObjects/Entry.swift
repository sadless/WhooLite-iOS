//
//  Entry.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 31..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class Entry: Object {
    dynamic var pk = ""
    dynamic var sectionId = ""
    dynamic var entryId = 0 as Int64
    dynamic var title = ""
    dynamic var money = 0.0
    dynamic var leftAccountType = ""
    dynamic var leftAccountId = ""
    dynamic var rightAccountType = ""
    dynamic var rightAccountId = ""
    dynamic var memo = ""
    dynamic var entryDate = 0.0
    
    override static func primaryKey() -> String? {
        return "pk"
    }
    
    func composePrimaryKey() {
        pk = sectionId + "|" + String(entryId)
    }
}
