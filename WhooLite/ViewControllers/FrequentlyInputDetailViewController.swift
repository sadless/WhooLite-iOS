//
//  FrequentlyInputDetailViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 1..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import SVProgressHUD
import RealmSwift

protocol FrequentlyInputDetailTableViewControllerDelegate {
    func didCompleteEntry(_ slotNumber: Int, itemId: String, itemTitle: String, money: String, leftAccountType: String, leftAccountId: String, rightAccountType: String, rightAccountId: String, memo: String)
    func didNotCompleteEntry()
}

class FrequentlyInputDetailViewController: DetailBaseViewController, SelectSlotNumberTableViewControllerDelegate {
    enum Mode {
        case edit
        case complete
    }
    
    var mode = Mode.edit
    var frequentItem: FrequentItem?
    var slotNumber: Int?
    var searchKeyword: String?
    var delegate: FrequentlyInputDetailTableViewControllerDelegate?
    var completed = false

    fileprivate var viewAppeared = false
    fileprivate var needSelectRight = false
    
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var sendButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var spaceButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        switch mode {
        case .edit:
            if frequentItem == nil {
                toolbarItems = [spaceButton, saveButton]
            } else {
                toolbarItems = [sendButton, spaceButton, saveButton, deleteButton]
            }
        case .complete:
            toolbarItems = [sendButton]
        }
        if let item = frequentItem {
            slotNumber = item.slotNumber
            searchKeyword = item.searchKeyword
        } else {
            slotNumber = 1
            searchKeyword = ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewAppeared {
            if mode == .complete {
                if getMoney() < WhooingKeyValues.epsilon {
                    let viewController = embeddedViewController as! DetailBaseTableViewController
                    
                    viewController.changeFirstResponderTo(viewController.moneyIndex - 1)
                }
                if (leftAccountType?.isEmpty)! {
                    performSegue(withIdentifier: "selectLeft", sender: nil)
                    needSelectRight = (rightAccountType?.isEmpty)!
                } else if (rightAccountType?.isEmpty)! {
                    performSegue(withIdentifier: "selectRight", sender: nil)
                }
            }
            viewAppeared = true
        } else if needSelectRight {
            performSegue(withIdentifier: "selectRight", sender: nil)
            needSelectRight = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !completed {
            delegate?.didNotCompleteEntry()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let identifier = segue.identifier {
            switch identifier {
            case "selectSlotNumber":
                let viewController = segue.destination as! SelectSlotNumberTableViewController
                
                viewController.slotNumber = slotNumber
                viewController.delegate = self
            default:
                break
            }
        }
    }
    
    // MARK: - Action methods
    
    @IBAction func saveTouched(_ sender: AnyObject?) {
        if (itemTitle?.isEmpty)! {
            let viewController = embeddedViewController as! DetailBaseTableViewController
            
            viewController.changeFirstResponderTo(viewController.itemTitleIndex)
        } else {
            SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
            if frequentItem == nil {
                NetworkUtility.postFrequentItem(slotNumber: slotNumber!, sectionId: sectionId!, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, itemTitle: itemTitle!, money: money, searchKeyword: searchKeyword!, completionHandler: { resultCode in
                    self.frequentItemSaved(resultCode)
                })
            } else {
                if slotNumber == frequentItem?.slotNumber {
                    NetworkUtility.putFrequentItem(slotNumber: slotNumber!, itemId: frequentItem!.itemId, sectionId: sectionId!, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, itemTitle: itemTitle!, money: money, searchKeyword: searchKeyword!, completionHandler: { resultCode in
                        self.frequentItemSaved(resultCode)
                    })
                } else {
                    deleteFrequentItem(true)
                }
            }
        }
    }
    
    @IBAction func sendTouched(_ sender: AnyObject?) {
        if (leftAccountType?.isEmpty)! {
            performSegue(withIdentifier: "selectLeft", sender: nil)
        } else if (rightAccountType?.isEmpty)! {
            performSegue(withIdentifier: "selectRight", sender: nil)
        } else {
            switch mode {
            case .edit:
                let prevEntries = DataUtility.duplicateEntries(with: try! Realm(), sectionId: sectionId!, entryDate: entryDateFormatter.string(from: Date()), itemTitle: itemTitle!, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, memo: "")
                
                if prevEntries.count > 0 {
                    let alertController = UIAlertController.init(title: NSLocalizedString("병합하기", comment: "병합하기"), message: NSLocalizedString("최근 내역중에 같은 내용으로 입력된 항목이 있습니다. 금액을 더해서 하나의 항목으로 병합할까요?", comment: "병합하기"), preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("병합하기", comment: "병합하기"), style: .default, handler: { action in
                        if prevEntries.count == 1 {
                            let entry = prevEntries.first!
                            let inputMoney = Double(self.money)!
                            
                            self.mergeSend(entryId: entry.entryId, mergedMoney: String(inputMoney + entry.money))
                        } else {
                            self.mergeArguments = [WhooingKeyValues.sectionId: self.sectionId!,
                                                                   WhooingKeyValues.entryDate: self.entryDateFormatter.string(from: Date()),
                                                                   WhooingKeyValues.leftAccountType: self.leftAccountType!,
                                                                   WhooingKeyValues.leftAccountId: self.leftAccountId!,
                                                                   WhooingKeyValues.rightAccountType: self.rightAccountType!,
                                                                   WhooingKeyValues.rightAccountId: self.rightAccountId!,
                                                                   WhooingKeyValues.itemTitle: self.itemTitle!,
                                                                   WhooingKeyValues.money: self.money,
                                                                   WhooingKeyValues.memo: ""]
                            self.performSegue(withIdentifier: "merge", sender: nil)
                        }
                    }))
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("새 항목으로 입력", comment: "새 항목으로 입력"), style: .destructive, handler: { action in
                        self.send()
                    }))
                    present(alertController, animated: true, completion: nil)
                } else {
                    send()
                }
            case .complete:
                let _ = navigationController?.popViewController(animated: true)
                
                completed = true
                delegate?.didCompleteEntry(slotNumber!, itemId: (frequentItem?.itemId)!, itemTitle: itemTitle!, money: money, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, memo: memo)
            }
        }
    }
    
    @IBAction func deleteTouched(_ sender: AnyObject) {
        let alertController = UIAlertController.init(title: NSLocalizedString("삭제 확인", comment: "삭제 확인"), message: NSLocalizedString("자주입력 거래를 삭제하시겠습니까?", comment: "삭제 확인"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("삭제", comment: "삭제"), style: .default, handler: {action in
            self.deleteFrequentItem()
        }))
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - SelectSlotNumberTableViewControllerDelegate methods
    
    func didSelectSlotNumber(_ number: Int) {
        slotNumber = number
        (embeddedViewController as! DetailBaseTableViewController).tableView.reloadData()
    }
    
    // MARK: - Instance methods
    
    override func getItemTitle() -> String {
        if let item = frequentItem {
            return item.title
        } else {
            return ""
        }
    }
    
    override func getMoney() -> Double {
        if let item = frequentItem {
            return item.money
        } else {
            return 0
        }
    }
    
    override func getLeftAccountType() -> String {
        if let item = frequentItem {
            return item.leftAccountType
        } else {
            return ""
        }
    }
    
    override func getLeftAccountId() -> String {
        if let item = frequentItem {
            return item.leftAccountId
        } else {
            return ""
        }
    }
    
    override func getRightAccountType() -> String {
        if let item = frequentItem {
            return item.rightAccountType
        } else {
            return ""
        }
    }
    
    override func getRightAccountId() -> String {
        if let item = frequentItem {
            return item.rightAccountId
        } else {
            return ""
        }
    }
    
    func entryInputed(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("거래 입력 실패", comment: "거래 입력 실패"), message: String.init(format: NSLocalizedString("[%1$@] 거래를 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 입력 실패"), itemTitle!), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.sendTouched(nil)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func frequentItemSaved(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("저장 실패", comment: "저장 실패"), message: NSLocalizedString("자주입력 거래를 수정하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "저장 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.saveTouched(nil)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func frequentItemDeleted(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("삭제 실패", comment: "삭제 실패"), message: NSLocalizedString("자주입력 거래를 삭제하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 삭제 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.deleteFrequentItem()
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func deleteFrequentItem(_ changeSlotNumber: Bool = false) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.deleteFrequentItem(slotNumber: frequentItem!.slotNumber, itemId: frequentItem!.itemId, sectionId: sectionId!, completionHandler: { resultCode in
            if changeSlotNumber {
                if resultCode == WhooingKeyValues.success {
                    var useCount = 0
                    var lastUseTime = 0.0
                    let realm = try! Realm()
                    let item = realm.objects(FrequentItem.self).filter("sectionId == %@ AND slotNumber == %d AND itemId == %@", self.sectionId!, self.frequentItem!.slotNumber, self.frequentItem!.itemId).first
                    
                    if let item = item {
                        useCount = item.useCount
                        lastUseTime = item.lastUseTime
                    }
                    NetworkUtility.postFrequentItem(slotNumber: self.slotNumber!, sectionId: self.sectionId!, leftAccountType: self.leftAccountType!, leftAccountId: self.leftAccountId!, rightAccountType: self.rightAccountType!, rightAccountId: self.rightAccountId!, itemTitle: self.itemTitle!, money: self.money, searchKeyword: self.searchKeyword!, useCount: useCount, lastUseTime: lastUseTime, completionHandler: { resultCode in
                        self.frequentItemSaved(resultCode)
                    })
                } else {
                    self.frequentItemSaved(resultCode)
                }
            } else {
                self.frequentItemDeleted(resultCode)
            }
        })
    }
    
    func send() {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.postEntry(sectionId: sectionId!, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, itemTitle: itemTitle!, money: money, memo: "", entryDate: nil, slotNumber: frequentItem!.slotNumber, frequentItemId: frequentItem!.itemId, completionHandler: { resultCode in
            self.entryInputed(resultCode)
        })
    }
    
    func mergeSend(entryId: Int64, mergedMoney: String) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.putEntry(sectionId: self.sectionId!, entryId: entryId, entryDate: entryDateFormatter.string(from: Date()), leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, itemTitle: itemTitle!, money: mergedMoney, memo: "", completionHandler: { resultCode in
            SVProgressHUD.dismiss()
            if resultCode < 0 {
                let alertController = UIAlertController.init(title: NSLocalizedString("거래 입력 실패", comment: "거래 입력 실패"), message: String.init(format: NSLocalizedString("[%1$@] 거래를 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 입력 실패"), self.itemTitle!), preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                    self.mergeSend(entryId: entryId, mergedMoney: mergedMoney)
                }))
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                    let _ = self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}
