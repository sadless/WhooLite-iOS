//
//  WhooLiteViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class WhooLiteViewController: UITabBarController, UINavigationControllerDelegate {
    fileprivate var sections: Results<Section>?
    fileprivate var sectionsNotificationToken: NotificationToken?
    fileprivate var currentSectionId: String?
    fileprivate var frequentItemsNotificationToken: NotificationToken?
    fileprivate var entriesNotificationToken: NotificationToken?

    var isSectionReceived = false
    var isAccountReceived = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sections = try! Realm().objects(Section.self).sorted(byProperty: "sortOrder", ascending: true)
        sectionsNotificationToken = sections?.addNotificationBlock({changes in
            if (self.sections?.count)! > 0 {
                var sectionChanged = false
                
                if self.currentSectionId == nil {
                    let userDefaults = UserDefaults.standard
                    
                    self.currentSectionId = userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) as? String
                    self.receiveAccounts()
                    sectionChanged = true
                } else {
                    let section = try! Realm().object(ofType: Section.self, forPrimaryKey: self.currentSectionId!)
                    
                    if section == nil {
                        self.currentSectionId = self.sections?[0].sectionId
                        self.receiveAccounts()
                        sectionChanged = true
                    }
                }
                if sectionChanged {
                    let userDefaults = UserDefaults.standard
                    
                    userDefaults.set(self.currentSectionId!, forKey: PreferenceKeyValues.currentSectionId)
                    userDefaults.synchronize()
                    self.restartNotificationTokens()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.sectionIdChanged), object: nil, userInfo: [Notifications.sectionId: self.currentSectionId!])
                }
            }
        })
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.init(Notifications.logout), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sectionIdChanged), name: NSNotification.Name.init(Notifications.sectionIdChanged), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.mainViewController = self
    }
    
    deinit {
        sectionsNotificationToken?.stop()
        frequentItemsNotificationToken?.stop()
        entriesNotificationToken?.stop()
        NotificationCenter.default.removeObserver(self)
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
    
    fileprivate func receiveSectionsWithDefault() {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: PreferenceKeyValues.currentSectionId) == nil {
            var url = URL.init(string: NetworkUtility.sectionsUrl)!
            
            url = url.appendingPathComponent("default.json")
            URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "GET", params: nil), completionHandler: {(data, response, error) in
                if error == nil {
                    let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                    let resultCode = json[WhooingKeyValues.code] as! Int
                    
                    if resultCode == WhooingKeyValues.success {
                        let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                        
                        userDefaults.set(resultItem[WhooingKeyValues.sectionId], forKey: PreferenceKeyValues.currentSectionId)
                        userDefaults.synchronize()
                        self.receiveSections()
                    } else {
                        self.sectionsReceived(resultCode)
                    }
                } else {
                    self.sectionsReceived(-1)
                }
            }).resume()
        } else {
            receiveSections()
        }
    }
    
    fileprivate func receiveSections() {
        var url = URL.init(string: NetworkUtility.sectionsUrl)!
        
        url = url.appendingPathExtension("json_array")
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(url, method: "GET", params: nil), completionHandler: {(data, response, error) in
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                let resultCode = json[WhooingKeyValues.code] as! Int
                
                if resultCode == WhooingKeyValues.success {
                    let sections = json[WhooingKeyValues.result] as! [[String: AnyObject]]
                    let realm = try! Realm()
                    var objects = [Section]()
                    var sectionIds = [String]()
                    var i = 0
                    
                    for section in sections {
                        let sectionId = section[WhooingKeyValues.sectionId] as! String
                        let object = Section()
                        
                        object.sectionId = sectionId
                        object.title = section[WhooingKeyValues.title] as! String
                        object.memo = section[WhooingKeyValues.memo] as! String
                        object.currency = section[WhooingKeyValues.currency] as! String
                        object.dateFormat = section[WhooingKeyValues.dateFormat] as! String
                        object.sortOrder = i
                        objects.append(object)
                        i += 1
                        sectionIds.append(sectionId)
                    }
                    try! realm.write({
                        realm.add(objects, update: true)
                        realm.delete(realm.objects(Section.self).filter("NOT (sectionId IN %@)", sectionIds))
                    })
                }
                self.sectionsReceived(resultCode)
            } else {
                self.sectionsReceived(-1)
            }
        }).resume()
    }
    
    fileprivate func sectionsReceived(_ resultCode: Int) {
        DispatchQueue.main.async(execute: {
            if (resultCode < 0) {
                if self.sections?.count == 0 {
                    let alertController = UIAlertController.init(title: NSLocalizedString("섹션 정보 없음", comment: "섹션 정보 없음"), message: NSLocalizedString("섹션 정보를 다운받지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "섹션 정보 없음"), preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: { action in
                        self.receiveSectionsWithDefault()
                    }))
                }
            } else {
                let _ = NetworkUtility.checkResultCodeWithAlert(resultCode)
                self.isSectionReceived = true
            }
        })
    }
    
    fileprivate func receiveAccounts() {
        var url = URL.init(string: NetworkUtility.accountsUrl)!
        
        url = url.appendingPathExtension("json_array")
        
        var urlComponents = URLComponents.init(string: url.absoluteString)!
        let dateFormatter = DateFormatter.init()
        
        dateFormatter.dateFormat = "yyyyMMdd"
        urlComponents.queryItems = [URLQueryItem.init(name: WhooingKeyValues.sectionId, value: currentSectionId),
                                    URLQueryItem.init(name: WhooingKeyValues.startDate, value: dateFormatter.string(from: Date.init()))]
        URLSession.shared.dataTask(with: NetworkUtility.requestForApiCall(urlComponents.url!, method: "GET", params: nil), completionHandler: {(data, response, error) in
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                let resultCode = json[WhooingKeyValues.code] as! Int
                
                if resultCode == WhooingKeyValues.success {
                    let accounts = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    var objects = [Account]()
                    var primaryKeys = [String]()
                    var i = 0
                    let keys = [WhooingKeyValues.assets, WhooingKeyValues.liabilities, WhooingKeyValues.capital, WhooingKeyValues.income, WhooingKeyValues.expenses]
                    
                    for key in keys {
                        let itemsInAccountType = accounts[key] as! [[String: AnyObject]]
                        
                        for account in itemsInAccountType {
                            let object = Account()
                            
                            object.sectionId = self.currentSectionId!
                            object.accountType = key
                            object.accountId = account[WhooingKeyValues.accountId] as! String
                            object.title = account[WhooingKeyValues.title] as! String
                            object.memo = account[WhooingKeyValues.memo] as! String
                            object.isGroup = account[WhooingKeyValues.type] as! String == WhooingKeyValues.group
                            object.sortOrder = i
                            object.composePrimaryKey()
                            objects.append(object)
                            i += 1
                            primaryKeys.append(object.pk)
                        }
                    }
                    try! realm.write({
                        realm.add(objects, update: true)
                        realm.delete(realm.objects(Account.self).filter("sectionId == %@ AND NOT (pk IN %@)", self.currentSectionId!, primaryKeys))
                    })
                }
                self.accountsReceived(resultCode)
            } else {
                self.accountsReceived(-1)
            }
        }).resume()

    }
    
    fileprivate func accountsReceived(_ resultCode: Int) {
        DispatchQueue.main.async(execute: {
            if (resultCode >= 0) {
                let _ = NetworkUtility.checkResultCodeWithAlert(resultCode)
                self.isAccountReceived = true
            }
        })
    }
    
    fileprivate func restartNotificationTokens(_ frequentItemsOnly: Bool = false) {
        let realm = try! Realm()
        let userDefaults = UserDefaults.standard
        var showSlotNumbers = userDefaults.object(forKey: PreferenceKeyValues.showSlotNumbers) as? Array<Int>
        
        if showSlotNumbers == nil {
            showSlotNumbers = [1, 2, 3]
        }
        frequentItemsNotificationToken?.stop()
        frequentItemsNotificationToken = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber IN %@", currentSectionId!, showSlotNumbers!).addNotificationBlock({ changes in
            switch changes {
            case .update(_, _, let insertions, _):
                if insertions.count > 0 && self.tabBar.items!.index(of: self.tabBar.selectedItem!) != 0 {
                    var count = insertions.count
                    
                    if let badgeValue = self.tabBar.items![0].badgeValue {
                        count += Int(badgeValue)!
                    }
                    self.tabBar.items![0].badgeValue = String(count)
                }
            default:
                break
            }
        })
        if !frequentItemsOnly {
            entriesNotificationToken?.stop()
            entriesNotificationToken = realm.objects(Entry.self).filter("sectionId == %@", currentSectionId!).addNotificationBlock({ changes in
                switch changes {
                case .update(_, _, let insertions, _):
                    if insertions.count > 0 && self.tabBar.items!.index(of: self.tabBar.selectedItem!) != 1 {
                        var count = insertions.count
                        
                        if let badgeValue = self.tabBar.items![1].badgeValue {
                            count += Int(badgeValue)!
                        }
                        self.tabBar.items![1].badgeValue = String(count)
                    }
                default:
                    break
                }
            })
        }
    }
    
    // MARK: - UINavigationControllerDelegate methods
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let vc = viewController as? WithAdmobViewController {
            if vc.embeddedViewController is WhooLiteTabBarItemBaseTableViewController {
                receiveSectionsWithDefault()
                if currentSectionId != nil {
                    receiveAccounts()
                }
            }
        }
    }
    
    // MARK: - Notification handler methods
    
    func logout() {
        sectionsNotificationToken?.stop()
    }
    
    func sectionIdChanged(_ notification: Notification) {
        currentSectionId = notification.userInfo?[Notifications.sectionId] as? String
        restartNotificationTokens()
    }
    
    // MARK: - UITabBarDelegate methods
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        item.badgeValue = nil
    }
}
