//
//  HistoryDetailViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 3..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import SVProgressHUD
import RealmSwift

class HistoryDetailViewController: DetailBaseViewController, HistoryTableViewControllerDelegate {
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBOutlet weak var spaceButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var copyButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    let entryDateFormat = DateFormatter.init()
    
    var entry: Entry?
    var entryDate: Int?
    var selectedSlotNumber: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        entryDateFormat.dateFormat = "yyyyMMdd"
        if let entry = entry {
            entryDate = Int(entry.entryDate)
            memo = entry.memo
            toolbarItems = [bookmarkButton, spaceButton, saveButton, copyButton, deleteButton]
        } else {
            entryDate = Int(entryDateFormat.string(from: Date()))
            toolbarItems = [sendButton]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Instance methods
    
    override func getMoney() -> Double {
        if let entry = entry {
            return entry.money
        } else {
            return 0
        }
    }

    override func getItemTitle() -> String {
        if let entry = entry {
            return entry.title
        } else {
            return ""
        }
    }
    
    override func getLeftAccountType() -> String {
        if let entry = entry {
            return entry.leftAccountType
        } else {
            return ""
        }
    }
    
    override func getLeftAccountId() -> String {
        if let entry = entry {
            return entry.leftAccountId
        } else {
            return ""
        }
    }
    
    override func getRightAccountType() -> String {
        if let entry = entry {
            return entry.rightAccountType
        } else {
            return ""
        }
    }
    
    override func getRightAccountId() -> String {
        if let entry = entry {
            return entry.rightAccountId
        } else {
            return ""
        }
    }
    
    func frequentItemSaved(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("북마크 실패", comment: "북마크 실패"), message: NSLocalizedString("자주입력 거래를 만들지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "북마크 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.bookmark(with: self.selectedSlotNumber!)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func entrySaved(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("수정 실패", comment: "수정 실패"), message: NSLocalizedString("거래내역을 수정하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "수정 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.saveTouched(self.saveButton)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func entryDeleted(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("삭제 실패", comment: "삭제 실패"), message: NSLocalizedString("거래내역을 삭제하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "삭제 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.deleteEntry(self.entry!.entryId)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let _ = navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func bookmark(with slotNumber: Int) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.postFrequentItem(slotNumber: slotNumber, sectionId: self.sectionId!, leftAccountType: self.leftAccountType!, leftAccountId: self.leftAccountId!, rightAccountType: self.rightAccountType!, rightAccountId: self.rightAccountId!, itemTitle: self.itemTitle!, money: self.money, searchKeyword: "", completionHandler: { resultCode in
            self.frequentItemSaved(resultCode)
        })
    }
    
    func deleteEntry(_ entryId: Int64) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.deleteEntry(sectionId: self.sectionId!, entryId: entryId, completionHandler: { resultCode in
            self.entryDeleted(resultCode)
        })
    }
    
    func editEntry() {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.putEntry(sectionId: self.sectionId!, entryId: entry!.entryId, entryDate: String(self.entryDate!), leftAccountType: self.leftAccountType!, leftAccountId: self.leftAccountId!, rightAccountType: self.rightAccountType!, rightAccountId: self.rightAccountId!, itemTitle: self.itemTitle!, money: self.money, memo: self.memo, completionHandler: { resultCode in
            self.entrySaved(resultCode)
        })
    }
    
    func mergeEdit(entryId: Int64, mergedMoney: String) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        NetworkUtility.putEntry(sectionId: self.sectionId!, entryId: entryId, entryDate: entryDateFormatter.string(from: Date()), leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, itemTitle: itemTitle!, money: mergedMoney, memo: "", completionHandler: { resultCode in
            if resultCode < 0 {
                SVProgressHUD.dismiss()
                let alertController = UIAlertController.init(title: NSLocalizedString("거래 입력 실패", comment: "거래 입력 실패"), message: String.init(format: NSLocalizedString("[%1$@] 거래를 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "거래 입력 실패"), self.itemTitle!), preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                    self.mergeEdit(entryId: entryId, mergedMoney: mergedMoney)
                }))
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.deleteEntry(self.entry!.entryId)
            }
        })
    }
    
    // MARK: - Action methods
    
    @IBAction func bookmarkTouched(_ sender: Any) {
        if (itemTitle?.isEmpty)! {
            let viewController = embeddedViewController as! DetailBaseTableViewController
            
            viewController.changeFirstResponderTo(viewController.itemTitleIndex)
        } else {
            let alertController = UIAlertController.init(title: NSLocalizedString("슬롯 번호 선택", comment: "슬롯 번호 선택"), message: nil, preferredStyle: .actionSheet)
            
            for i in 1...3 {
                alertController.addAction(UIAlertAction.init(title: String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호 선텍"), i), style: .default, handler: {action in
                    let slotNumber = alertController.actions.index(of: action)! + 1
                    
                    self.bookmark(with: slotNumber)
                }))
            }
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveTouched(_ sender: Any) {
        let prevEntries = DataUtility.duplicateEntries(with: try! Realm(), sectionId: sectionId!, entryDate: entryDateFormatter.string(from: Date()), itemTitle: itemTitle!, leftAccountType: leftAccountType!, leftAccountId: leftAccountId!, rightAccountType: rightAccountType!, rightAccountId: rightAccountId!, memo: self.memo)

        if prevEntries.count > 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("병합하기", comment: "병합하기"), message: NSLocalizedString("최근 내역중에 같은 내용으로 입력된 항목이 있습니다. 금액을 더해서 하나의 항목으로 병합할까요?", comment: "병합하기"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("병합하기", comment: "병합하기"), style: .default, handler: { action in
                if prevEntries.count == 1 {
                    let entry = prevEntries.first!
                    let inputMoney = Double(self.money)!

                    self.mergeEdit(entryId: entry.entryId, mergedMoney: String(inputMoney + entry.money))
                } else {
                    self.mergeArguments = [WhooingKeyValues.sectionId: self.sectionId!,
                                           WhooingKeyValues.entryDate: self.entryDateFormatter.string(from: Date()),
                                           WhooingKeyValues.leftAccountType: self.leftAccountType!,
                                           WhooingKeyValues.leftAccountId: self.leftAccountId!,
                                           WhooingKeyValues.rightAccountType: self.rightAccountType!,
                                           WhooingKeyValues.rightAccountId: self.rightAccountId!,
                                           WhooingKeyValues.itemTitle: self.itemTitle!,
                                           WhooingKeyValues.money: self.money,
                                           WhooingKeyValues.memo: "",
                                           WhooingKeyValues.entryId: String(self.entry!.entryId)]
                    self.mergeDelegate = self
                    self.performSegue(withIdentifier: "merge", sender: nil)
                }
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("이 항목만 수정", comment: "이 항목만 수정"), style: .destructive, handler: { action in
                self.editEntry()
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            editEntry()
        }
    }
    
    @IBAction func copyTouched(_ sender: Any) {
        let _ = navigationController?.popViewController(animated: true) as! HistoryDetailViewController
        let viewController = storyboard!.instantiateViewController(withIdentifier: "HistoryDetailViewController") as! HistoryDetailViewController
        
        viewController.itemTitle = itemTitle
        viewController.money = money
        viewController.leftAccountType = leftAccountType
        viewController.leftAccountId = leftAccountId
        viewController.rightAccountType = rightAccountType
        viewController.rightAccountId = rightAccountId
        viewController.memo = memo
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func deleteTouched(_ sender: Any) {
        let alertController = UIAlertController.init(title: NSLocalizedString("삭제 확인", comment: "삭제 확인"), message: NSLocalizedString("거래내역을 삭제하시겠습니까?", comment: "삭제 확인"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("삭제", comment: "삭제"), style: .default, handler: { action in
            self.deleteEntry(self.entry!.entryId)
        }))
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendTouched(_ sender: Any) {
        if (leftAccountType?.isEmpty)! {
            performSegue(withIdentifier: "selectLeft", sender: nil)
        } else if (rightAccountType?.isEmpty)! {
            performSegue(withIdentifier: "selectRight", sender: nil)
        } else {
            SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
            NetworkUtility.postEntry(sectionId: self.sectionId!, leftAccountType: self.leftAccountType!, leftAccountId: self.leftAccountId!, rightAccountType: self.rightAccountType!, rightAccountId: self.rightAccountId!, itemTitle: self.itemTitle!, money: self.money, memo: self.memo, entryDate: String(entryDate!), slotNumber: nil, frequentItemId: nil, completionHandler: { resultCode in
                SVProgressHUD.dismiss()
                if resultCode < 0 {
                    let alertController = UIAlertController.init(title: NSLocalizedString("입력 실패", comment: "입력 실패"), message: NSLocalizedString("거래내역을 입력하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "입력 실패"), preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                        self.sendTouched(self.sendButton)
                    }))
                    alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                        let _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            })
        }
    }
    
    // MARK: - HistoryTableViewControllerDelegate methods
    
    func didMergeEntries() {
        self.deleteEntry(self.entry!.entryId)
    }
}
