//
//  FrequentlyInputDetailViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 1..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class FrequentlyInputDetailViewController: DetailBaseViewController, SelectSlotNumberTableViewControllerDelegate {
    var frequentItem: FrequentItem?
    var slotNumber: Int?
    var searchKeyword: String?
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var sendButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var spaceButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        toolbarItems = [sendButton, spaceButton, saveButton, deleteButton]
        slotNumber = frequentItem?.slotNumber
        searchKeyword = frequentItem?.searchKeyword
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if let identifier = segue.identifier {
            switch identifier {
            case "selectSlotNumber":
                let viewController = segue.destinationViewController as! SelectSlotNumberTableViewController
                
                viewController.slotNumber = slotNumber
                viewController.delegate = self
            default:
                break
            }
        }
    }
    
    // MARK: - Action methods
    
    @IBAction func saveTouched(sender: AnyObject) {
    }
    
    @IBAction func sendTouched(sender: AnyObject) {
    }
    
    @IBAction func deleteTouched(sender: AnyObject) {
    }
    
    // MARK: - SelectSlotNumberTableViewControllerDelegate methods
    
    func didSelectSlotNumber(number: Int) {
        slotNumber = number
        (embeddedViewController as! DetailBaseTableViewController).tableView.reloadData()
    }
    
    // MARK: - Instance methods
    
    override func getItemTitle() -> String {
        return (frequentItem?.title)!
    }
    
    override func getMoney() -> Double {
        return (frequentItem?.money)!
    }
    
    override func getLeftAccountType() -> String {
        return (frequentItem?.leftAccountType)!
    }
    
    override func getLeftAccountId() -> String {
        return (frequentItem?.leftAccountId)!
    }
    
    override func getRightAccountType() -> String {
        return (frequentItem?.rightAccountType)!
    }
    
    override func getRightAccountId() -> String {
        return (frequentItem?.rightAccountId)!
    }
}
