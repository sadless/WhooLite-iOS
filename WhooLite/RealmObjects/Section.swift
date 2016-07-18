//
//  Section.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class Section: Object {
    dynamic var sectionId = ""
    dynamic var title = ""
    dynamic var memo = ""
    dynamic var currency = ""
    dynamic var dateFormat = ""
    dynamic var sortOrder = 0
    
    override static func primaryKey() -> String? {
        return "sectionId"
    }
}
