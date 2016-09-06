//
//  WithAdmobViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 1..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import Firebase

class WithAdmobViewController: UIViewController {
    
    @IBOutlet weak var adBannerView: GADBannerView!

    var embeddedViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let request = GADRequest()
        
        adBannerView.adUnitID = ApiKeys.bannerAdUnitId
        request.testDevices = [kGADSimulatorID, ApiKeys.testDevice]
        adBannerView.loadRequest(request)
        navigationController?.delegate = tabBarController as! WhooLiteViewController
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

}
