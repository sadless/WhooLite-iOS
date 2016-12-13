//
//  PreferenceKeys.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 14..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class PreferenceKeyValues: NSObject {
    static let apiKeyFormat = "apiKeyFormat"
    static let currentSectionId = "currentSectionId"
    static let showSlotNumbers = "showSlotNumbers"
    static let frequentlyInputSortOrder = "frequentlyInputSortOrder"
    
    enum FrequentlyInputSortOrder: Int {
        case serverSettings = 0
        case frequentlyUse
        case lastUse
        
        init(rawValue: Int) {
            switch rawValue {
            case 1:
                self = .frequentlyUse
            case 2:
                self = .lastUse
            default:
                self = .serverSettings
            }
        }
    }
}
