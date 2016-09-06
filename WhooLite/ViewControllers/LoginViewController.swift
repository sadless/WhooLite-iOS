//
//  LoginViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

protocol LoginViewControllerDelegate: NSObjectProtocol {
    func didLogin(apiKeyFormat: String)
}

class LoginViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var whooingWebView: UIWebView!
    @IBOutlet weak var failedView: UIView!
    
    private let requestTokenUrl = "https://whooing.com/app_auth/request_token"
    private let authorizeUrl = "https://whooing.com/app_auth/authorize?no_register=y"
    private let requestAccessTokenUrl = "https://whooing.com/app_auth/access_token"
    
    private var token: String?
    private var pin: String?
    
    var delegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    @IBAction func cancelTouched(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func retryTouched(sender: AnyObject) {
        failedView.hidden = true
        activityIndicator.hidden = false
        if token == nil {
            requestToken()
        } else {
            requestAccessToken()
        }
    }
    
    // MARK: - Instance methods
    private func requestToken() {
        let urlComponents = NSURLComponents.init(string: requestTokenUrl)!
        
        urlComponents.queryItems = [NSURLQueryItem.init(name: WhooingKeyValues.appId, value: ApiKeys.appId),
            NSURLQueryItem.init(name: WhooingKeyValues.appSecret, value: ApiKeys.appSecret)]
        NSURLSession.sharedSession().dataTaskWithURL(urlComponents.URL!, completionHandler: {(data, response, error) in
            if error == nil {
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                let urlComponents = NSURLComponents.init(string: self.authorizeUrl)!
                var queryItems = urlComponents.queryItems!
                
                self.token = json[WhooingKeyValues.token] as? String
                queryItems.append(NSURLQueryItem.init(name: WhooingKeyValues.token, value: self.token))
                urlComponents.queryItems = queryItems
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.hidden = true
                    self.whooingWebView.hidden = false
                    self.whooingWebView.loadRequest(NSURLRequest.init(URL: urlComponents.URL!))
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.hidden = true
                    self.failedView.hidden = false
                })
            }
        }).resume()
    }
    
    private func requestAccessToken() {
        let urlComponents = NSURLComponents.init(string: requestAccessTokenUrl)!
        
        urlComponents.queryItems = [NSURLQueryItem.init(name: WhooingKeyValues.appId, value: ApiKeys.appId),
                                    NSURLQueryItem.init(name: WhooingKeyValues.appSecret, value: ApiKeys.appSecret),
                                    NSURLQueryItem.init(name: WhooingKeyValues.token, value: token),
                                    NSURLQueryItem.init(name: WhooingKeyValues.pin, value: pin)]
        NSURLSession.sharedSession().dataTaskWithURL(urlComponents.URL!, completionHandler: {(data, response, error) in
            if error != nil {
                let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                let appName = NSBundle.mainBundle().localizedInfoDictionary?["CFBundleDisplayName"] as! String
                var apiKeyFormat = WhooingKeyValues.appId + "=" + ApiKeys.appId + ","
                
                apiKeyFormat += WhooingKeyValues.token + "=" + (json[WhooingKeyValues.token] as! String) + ","
                apiKeyFormat += WhooingKeyValues.signature + "=" + self.sha1(ApiKeys.appSecret + "|" + (json[WhooingKeyValues.tokenSecret] as! String)) + ","
                apiKeyFormat += WhooingKeyValues.nonce + "=" + appName + ","
                apiKeyFormat += WhooingKeyValues.timestamp + "=%f"
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: {
                        self.delegate?.didLogin(apiKeyFormat)
                    })
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.hidden = true
                    self.failedView.hidden = false
                })
            }
        }).resume()
    }
    
    private func sha1(string: String) -> String {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        
        let hexBytes = digest.map {String.init(format: "%02hhx", $0)}
        
        return hexBytes.joinWithSeparator("")
    }
    
    // MARK: - UIWebViewDelegate methods
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let urlComponents = NSURLComponents.init(string: request.URL!.absoluteString)!
        if let queryItems = urlComponents.queryItems {
            for queryItem in queryItems {
                if queryItem.name == WhooingKeyValues.pin {
                    whooingWebView.hidden = true
                    activityIndicator.hidden = false
                    pin = queryItem.value
                    requestAccessToken()
                }
            }
        }
        
        return true
    }
}
