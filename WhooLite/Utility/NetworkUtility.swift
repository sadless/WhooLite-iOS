//
//  NetworkUtility.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class NetworkUtility: NSObject {
    static let sectionsUrl = "https://whooing.com/api/sections"
    static let accountsUrl = "https://whooing.com/api/accounts"
    static let frequentItemsUrl = "https://whooing.com/api/frequent_items"
    static let entriesUrl = "https://whooing.com/api/entries"
    
    static func requestForApiCall(url: NSURL, method: String, params: [String: String]?) -> NSURLRequest {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let apiKey = String.init(format: userDefaults.objectForKey(PreferenceKeys.apiKeyFormat) as! String, NSDate.init().timeIntervalSince1970)
        let request = NSMutableURLRequest.init(URL: url)
        
        request.setValue(apiKey, forHTTPHeaderField: WhooingKeyValues.apiKey)
        request.HTTPMethod = method
        if let postParams = params {
            let urlComponents = NSURLComponents.init()
            var queryItems = [NSURLQueryItem]()
            
            for key in postParams.keys {
                queryItems.append(NSURLQueryItem.init(name: key, value: postParams[key]))
            }
            urlComponents.queryItems = queryItems
            request.HTTPBody = urlComponents.query?.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        return request
    }
    
    static func checkResultCodeWithAlert(code: Int) -> Bool {
        switch code {
        case 405:
            let alertController = UIAlertController.init(title: NSLocalizedString("토큰 만료됨", comment: "토큰 만료됨"), message: NSLocalizedString("인증토큰이 만료되어 다시 로그인 하셔야 합니다.", comment: "토큰 만료됨"), preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 로그인", comment: "다시 로그인"), style: .Default, handler: { action in
                let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                delegate.logout()
            }))
            return false
        default:
            return true
        }
    }
}
