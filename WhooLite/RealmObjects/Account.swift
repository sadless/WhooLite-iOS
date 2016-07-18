//
//  Account.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 17..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class Account: Object {
    dynamic var pk = ""
    dynamic var sectionId = ""
    dynamic var accountType = ""
    dynamic var accountId = ""
    dynamic var title = ""
    dynamic var memo = ""
    dynamic var isGroup = false
    dynamic var sortOrder = 0
    
    override static func primaryKey() -> String? {
        return "pk"
    }
    
    func composePrimaryKey() {
        pk = sectionId + "|" + accountType + "|" + accountId
    }
}
