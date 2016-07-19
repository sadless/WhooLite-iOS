//
//  FrequentItem.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 19..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class FrequentItem: Object {
    dynamic var pk = ""
    dynamic var sectionId = ""
    dynamic var slotNumber = 0
    dynamic var itemId = ""
    dynamic var title = ""
    dynamic var money = 0.0
    dynamic var leftAccountType = ""
    dynamic var leftAccountId = ""
    dynamic var rightAccountType = ""
    dynamic var rightAccountId = ""
    dynamic var useCount = 0
    dynamic var lastUseTime = 0.0
    dynamic var sortOrder = 0
    dynamic var searchKeyword = ""
    
    override static func primaryKey() -> String? {
        return "pk"
    }
    
    func composePrimaryKey() {
        pk = sectionId + "|" + String(slotNumber) + "|" + itemId
    }
}
