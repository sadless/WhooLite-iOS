//
//  WhooLiteViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift

class WhooLiteViewController: UITabBarController {
    private let sectionsUrl = "https://whooing.com/api/sections"
    private let accountsUrl = "https://whooing.com/api/accounts"
    
    private var sections: Results<Section>?
    private var sectionsNotificationToken: NotificationToken?
    private var currentSectionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sections = try! Realm().objects(Section.self).sorted("sortOrder", ascending: true)
        sectionsNotificationToken = sections?.addNotificationBlock({changes in
            if self.sections?.count > 0 {
                var sectionChanged = false
                
                if self.currentSectionId == nil {
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    
                    self.currentSectionId = userDefaults.objectForKey(PreferenceKeys.currentSectionId) as? String
                    self.receiveAccounts()
                    sectionChanged = true
                } else {
                    let section = try! Realm().objectForPrimaryKey(Section.self, key: self.currentSectionId!)
                    
                    if section == nil {
                        self.currentSectionId = self.sections?[0].sectionId
                        self.receiveAccounts()
                        sectionChanged = true
                    }
                }
                if sectionChanged {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.sectionIdChanged, object: nil, userInfo: [Notifications.sectionId: self.currentSectionId!])
                }
            }
        })
    }
    
    deinit {
        sectionsNotificationToken?.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        receiveSectionsWithDefault()
        if currentSectionId != nil {
            receiveAccounts()
        }
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
    
    private func receiveSectionsWithDefault() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(PreferenceKeys.currentSectionId) == nil {
            var url = NSURL.init(string: sectionsUrl)!
            
            url = url.URLByAppendingPathComponent("default.json")
            NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(url, method: "GET", params: nil), completionHandler: {(data, response, error) in
                if let resultData = data {
                    let json = try! NSJSONSerialization.JSONObjectWithData(resultData, options: []) as! [String: AnyObject]
                    let resultCode = json[WhooingKeyValues.code] as! Int
                    
                    if resultCode == WhooingKeyValues.success {
                        let resultItem = json[WhooingKeyValues.result] as! [String: AnyObject]
                        
                        userDefaults.setObject(resultItem[WhooingKeyValues.sectionId], forKey: PreferenceKeys.currentSectionId)
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
    
    private func receiveSections() {
        var url = NSURL.init(string: sectionsUrl)!
        
        url = url.URLByAppendingPathExtension("json_array")
        NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(url, method: "GET", params: nil), completionHandler: {(data, response, error) in
            if let resultData = data {
                let json = try! NSJSONSerialization.JSONObjectWithData(resultData, options: []) as! [String: AnyObject]
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
                } else {
                    self.sectionsReceived(resultCode)
                }
            } else {
                self.sectionsReceived(-1)
            }
        }).resume()
    }
    
    private func sectionsReceived(resultCode: Int) {
        dispatch_async(dispatch_get_main_queue(), {
            if (resultCode < 0) {
                if self.sections?.count == 0 {
                    let alertController = UIAlertController.init(title: NSLocalizedString("섹션 정보 없음", comment: "섹션 정보 없음"), message: NSLocalizedString("섹션 정보를 다운받지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "섹션 정보 없음"), preferredStyle: .Alert)
                    
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .Default, handler: { action in
                        self.receiveSectionsWithDefault()
                    }))
                }
            } else {
                NetworkUtility.checkResultCodeWithAlert(resultCode)
            }
        })
    }
    
    private func receiveAccounts() {
        var url = NSURL.init(string: accountsUrl)!
        
        url = url.URLByAppendingPathExtension("json_array")
        
        let urlComponents = NSURLComponents.init(string: url.absoluteString)!
        let dateFormatter = NSDateFormatter.init()
        
        dateFormatter.dateFormat = "yyyyMMdd"
        urlComponents.queryItems = [NSURLQueryItem.init(name: WhooingKeyValues.sectionId, value: currentSectionId),
                                    NSURLQueryItem.init(name: WhooingKeyValues.startDate, value: dateFormatter.stringFromDate(NSDate.init()))]
        NSURLSession.sharedSession().dataTaskWithRequest(NetworkUtility.requestForApiCall(urlComponents.URL!, method: "GET", params: nil), completionHandler: {(data, response, error) in
            if let resultData = data {
                let json = try! NSJSONSerialization.JSONObjectWithData(resultData, options: []) as! [String: AnyObject]
                let resultCode = json[WhooingKeyValues.code] as! Int
                
                if resultCode == WhooingKeyValues.success {
                    let accounts = json[WhooingKeyValues.result] as! [String: AnyObject]
                    let realm = try! Realm()
                    var objects = [Account]()
                    var primaryKeys = [String]()
                    var i = 0
                    
                    for key in accounts.keys {
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
                        realm.delete(realm.objects(Account.self).filter("NOT (pk IN %@)", primaryKeys))
                    })
                } else {
                    self.accountsReceived(resultCode)
                }
            } else {
                self.accountsReceived(-1)
            }
        }).resume()

    }
    
    private func accountsReceived(resultCode: Int) {
        dispatch_async(dispatch_get_main_queue(), {
            if (resultCode >= 0) {
                NetworkUtility.checkResultCodeWithAlert(resultCode)
            }
        })
    }
}
