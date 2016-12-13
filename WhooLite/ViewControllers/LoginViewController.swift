//
//  LoginViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

protocol LoginViewControllerDelegate: NSObjectProtocol {
    func didLogin(_ apiKeyFormat: String)
}

class LoginViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var whooingWebView: UIWebView!
    @IBOutlet weak var failedView: UIView!
    
    fileprivate let requestTokenUrl = "https://whooing.com/app_auth/request_token"
    fileprivate let authorizeUrl = "https://whooing.com/app_auth/authorize?no_register=y"
    fileprivate let requestAccessTokenUrl = "https://whooing.com/app_auth/access_token"
    
    fileprivate var token: String?
    fileprivate var pin: String?
    
    var delegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let cookieStorage = HTTPCookieStorage.shared
        
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }
        requestToken()
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

    // MARK: - Action methods
    
    @IBAction func cancelTouched(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func retryTouched(_ sender: AnyObject) {
        failedView.isHidden = true
        activityIndicator.isHidden = false
        if token == nil {
            requestToken()
        } else {
            requestAccessToken()
        }
    }
    
    // MARK: - Instance methods
    fileprivate func requestToken() {
        var urlComponents = URLComponents.init(string: requestTokenUrl)!
        
        urlComponents.queryItems = [URLQueryItem.init(name: WhooingKeyValues.appId, value: ApiKeys.appId),
            URLQueryItem.init(name: WhooingKeyValues.appSecret, value: ApiKeys.appSecret)]
        URLSession.shared.dataTask(with: urlComponents.url!, completionHandler: {(data, response, error) in
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                var urlComponents = URLComponents.init(string: self.authorizeUrl)!
                var queryItems = urlComponents.queryItems!
                
                self.token = json[WhooingKeyValues.token] as? String
                queryItems.append(URLQueryItem.init(name: WhooingKeyValues.token, value: self.token))
                urlComponents.queryItems = queryItems
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.isHidden = true
                    self.whooingWebView.isHidden = false
                    self.whooingWebView.loadRequest(URLRequest.init(url: urlComponents.url!))
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.isHidden = true
                    self.failedView.isHidden = false
                })
            }
        }).resume()
    }
    
    fileprivate func requestAccessToken() {
        var urlComponents = URLComponents.init(string: requestAccessTokenUrl)!
        
        urlComponents.queryItems = [URLQueryItem.init(name: WhooingKeyValues.appId, value: ApiKeys.appId),
                                    URLQueryItem.init(name: WhooingKeyValues.appSecret, value: ApiKeys.appSecret),
                                    URLQueryItem.init(name: WhooingKeyValues.token, value: token),
                                    URLQueryItem.init(name: WhooingKeyValues.pin, value: pin)]
        URLSession.shared.dataTask(with: urlComponents.url!, completionHandler: {(data, response, error) in
            if error == nil {
                let json = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                let appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as! String
                var apiKeyFormat = WhooingKeyValues.appId + "=" + ApiKeys.appId + ","
                
                apiKeyFormat += WhooingKeyValues.token + "=" + (json[WhooingKeyValues.token] as! String) + ","
                apiKeyFormat += WhooingKeyValues.signature + "=" + self.sha1(ApiKeys.appSecret + "|" + (json[WhooingKeyValues.tokenSecret] as! String)) + ","
                apiKeyFormat += WhooingKeyValues.nonce + "=" + appName + ","
                apiKeyFormat += WhooingKeyValues.timestamp + "=%f"
                DispatchQueue.main.async(execute: {
                    self.dismiss(animated: true, completion: {
                        self.delegate?.didLogin(apiKeyFormat)
                    })
                })
            } else {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.isHidden = true
                    self.failedView.isHidden = false
                })
            }
        }).resume()
    }
    
    fileprivate func sha1(_ string: String) -> String {
        let data = string.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        
        let hexBytes = digest.map {String.init(format: "%02hhx", $0)}
        
        return hexBytes.joined(separator: "")
    }
    
    // MARK: - UIWebViewDelegate methods
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let urlComponents = URLComponents.init(string: request.url!.absoluteString)!
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                if queryItem.name == WhooingKeyValues.pin {
                    whooingWebView.isHidden = true
                    activityIndicator.isHidden = false
                    pin = queryItem.value
                    requestAccessToken()
                }
            }
        }
        
        return true
    }
}
