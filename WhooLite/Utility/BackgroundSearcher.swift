//
//  BackgroundSearcher.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 10. 24..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

protocol BackgroundSearcherDelegate {
    func didSearch(_ searchedItems: [String]?)
}

class BackgroundSearcher: NSObject {
    var canceled = false
    
    func search(with sectionId: String, keyword: String, delegate: BackgroundSearcherDelegate) {
        DispatchQueue.global().async {
            var pks: [String]? = [String]()
            
            if !keyword.isEmpty {
                let userDefaults = UserDefaults.standard
                let showSlotNumbers = userDefaults.object(forKey: PreferenceKeyValues.showSlotNumbers) as? [Int]
                var items = try! Realm().objects(FrequentItem.self).filter("sectionId == %@", sectionId)
                
                if showSlotNumbers != nil && (showSlotNumbers?.count)! < 3 {
                    items = items.filter("slotNumber IN %@", showSlotNumbers!)
                }
                for item in items {
                    if self.canceled {
                        return
                    }
                    let trimmedTitle = item.title.trimmingCharacters(in: CharacterSet.whitespaces)
                    
                    if SoundSearcher.matchString(trimmedTitle, search: keyword) {
                        pks?.append(item.pk)
                    } else if !item.searchKeyword.isEmpty {
                        let trimmedKeyword = item.searchKeyword.trimmingCharacters(in: CharacterSet.whitespaces)
                        
                        if SoundSearcher.matchString(trimmedKeyword, search: keyword) {
                            pks?.append(item.pk)
                        }
                    }
                }
            } else {
                pks = nil
            }
            if !self.canceled {
                DispatchQueue.main.async(execute: {
                    delegate.didSearch(pks)
                })
            }
        }
    }
}
