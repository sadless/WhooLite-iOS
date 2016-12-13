//
//  AppDelegate.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 12..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift
import Firebase
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainViewController: WhooLiteViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: PreferenceKeyValues.apiKeyFormat) == nil {
            window?.rootViewController = window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "login")
        }
        UINavigationBar.appearance().barTintColor = UIColor.init(red: 0xFF / 255.0, green: 0xEB / 255.0, blue: 0x3B / 255.0, alpha: 1)
        FIRApp.configure()
        SVProgressHUD.setDefaultMaskType(.gradient)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Instance methods
    
    func logout() {
        let realm = try! Realm()
        let userDefaults = UserDefaults.standard
        
        NotificationCenter.default.post(name: NSNotification.Name.init(Notifications.logout), object: nil)
        try! realm.write({
            realm.deleteAll()
        })
        userDefaults.removeObject(forKey: PreferenceKeyValues.frequentlyInputSortOrder)
        userDefaults.removeObject(forKey: PreferenceKeyValues.showSlotNumbers)
        userDefaults.removeObject(forKey: PreferenceKeyValues.apiKeyFormat)
        userDefaults.removeObject(forKey: PreferenceKeyValues.currentSectionId)
        userDefaults.synchronize()
        mainViewController?.performSegue(withIdentifier: "logout", sender: nil)
    }
}

