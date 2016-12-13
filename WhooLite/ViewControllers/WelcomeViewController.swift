//
//  WelcomeViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, LoginViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == nil {
            let navController = segue.destination as! UINavigationController
            let viewController = navController.viewControllers[0] as! LoginViewController
            
            viewController.delegate = self
        }
    }
    
    // MARK: - LoginViewControllerDelegate methods
    
    func didLogin(_ apiKeyFormat: String) {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(apiKeyFormat, forKey: PreferenceKeyValues.apiKeyFormat)
        userDefaults.synchronize()
        performSegue(withIdentifier: "logined", sender: nil)
    }
}
