//
//  ManualViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 15..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class ManualViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var manualScrollView: UIScrollView!
    @IBOutlet weak var manualPageControl: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    @IBAction func doneTouched(_ sender: AnyObject) {
        navigationController?.performSegue(withIdentifier: "start", sender: nil)
    }
    
    // MARK: - UIScrollViewDelegate methods
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        manualPageControl.currentPage = Int(scrollView.contentOffset.x / view.frame.width)
    }
}
