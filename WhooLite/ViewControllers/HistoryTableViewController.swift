//
//  HistoryTableViewController.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 10. 29..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

class HistoryTableViewController: WhooLiteTabBarItemBaseTableViewController {
    var entries: Results<Entry>?
    var entriesNotificationToken: NotificationToken?
    var sectionDateFormat: DateFormatter?
    var bookmarkingSlotNumber: Int?
    var bookmarkingParams = [[String: String]]()
    var mergeArguments: [String: String]?
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItemIndex = 1
        deleteConfirmString = NSLocalizedString("선택하신 %1$d개의 거래내역을 삭제하시겠습니까?", comment: "삭제 확인")
        if sectionId != nil {
            sectionChanged()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: NSNotification.Name.init(Notifications.logout), object: nil)
        
        if mergeArguments != nil {
            title = NSLocalizedString("병합할 항목 선택", comment: "병합할 항목 선택")
            navigationItem.rightBarButtonItem = doneButton
        }
    }
    
    deinit {
        entriesNotificationToken?.stop()
        NotificationCenter.default.removeObserver(self)
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
    
    override func refreshMainData() {
        NetworkUtility.getEntries(sectionId: sectionId!, completionHandler: { resultCode in
            self.mainDataReceived(resultCode)
        })
    }
    
    override func sectionChanged() {
        if let arguments = mergeArguments {
            entries = DataUtility.duplicateEntries(with: try! Realm(), args: arguments)
        } else {
            entries = try! Realm().objects(Entry.self).filter("sectionId == %@", sectionId!).sorted(byProperty: "entryDate", ascending: false)
        }
        entriesNotificationToken?.stop()
        entriesNotificationToken = entries?.addNotificationBlock({ changes in
            self.refreshSections()
            self.tableView.reloadData()
        })
    }
    
    override func refreshSections() {
        sectionTitles.removeAll()
        sectionDataCounts.removeAll()
        
        var needSection = sectionId != nil
        
        if needSection {
            needSection = (entries?.count)! > 0
            if needSection {
                var entryDate = Int((entries?[0].entryDate)!)
                var count = 0
                
                for entry in entries! {
                    if entryDate == Int(entry.entryDate) {
                        count += 1
                    } else {
                        sectionTitles.append(sectionDateFormat!.string(from: entryDateFormat.date(from: String(entryDate))!))
                        sectionDataCounts.append(count)
                        entryDate = Int(entry.entryDate)
                        count = 1
                    }
                }
                needSection = sectionTitles.count > 0
                if needSection {
                    sectionTitles.append(sectionDateFormat!.string(from: entryDateFormat.date(from: String(entryDate))!))
                    sectionDataCounts.append(count)
                } else {
                    sectionDataCounts.append((entries?.count)!)
                }
            }
        }
    }
    
    override func getDataFromSection(_ _section: Results<Section>) {
        super.getDataFromSection(_section)
        if _section.count > 0 {
            sectionDateFormat = DataUtility.dateFormat(from: _section[0].dateFormat)
        }
    }
    
    override func dataMoney(_ indexPath: IndexPath) -> Double {
        return itemAtIndexPath(indexPath).money
    }
    
    override func dataLeftAccountType(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountType
    }
    
    override func dataLeftAccountId(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).leftAccountId
    }
    
    override func dataRightAccountType(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountType
    }
    
    override func dataRightAccountId(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).rightAccountId
    }
    
    override func dataTitle(_ indexPath: IndexPath) -> String {
        return itemAtIndexPath(indexPath).title
    }
    
    override func deleteCall() {
        var entryIds = [Int64]()

        for indexPath in selectedIndexPaths! {
            let entry = itemAtIndexPath(indexPath)
            
            entryIds.append(entry.entryId)
        }
        NetworkUtility.deleteEntries(sectionId: self.sectionId!, entryIds: entryIds, completionHandler: { resultCode in
            self.didDeleteSelectedItems(resultCode: resultCode)
        })
    }
    
    override func otherActionWithSelectedItems() {
        selectedIndexPaths = tableView.indexPathsForSelectedRows
        let alertController = UIAlertController.init(title: NSLocalizedString("슬롯 번호 선택", comment: "슬롯 번호 선택"), message: nil, preferredStyle: .actionSheet)
        
        for i in 1...3 {
            alertController.addAction(UIAlertAction.init(title: String.init(format: NSLocalizedString("%1$d번 슬롯", comment: "슬롯 번호 선텍"), i), style: .default, handler: {action in
                self.bookmarkingSlotNumber = alertController.actions.index(of: action)! + 1

                let realm = try! Realm()
                
                for indexPath in self.selectedIndexPaths! {
                    let entry = realm.objects(Entry.self).filter("sectionId == %@ AND entryId == %lld", self.sectionId!, self.itemAtIndexPath(indexPath).entryId).first!
                    let params = [WhooingKeyValues.sectionId: self.sectionId!,
                                  WhooingKeyValues.leftAccountType: entry.leftAccountType,
                                  WhooingKeyValues.leftAccountId: entry.leftAccountId,
                                  WhooingKeyValues.rightAccountType: entry.rightAccountType,
                                  WhooingKeyValues.rightAccountId: entry.rightAccountId,
                                  WhooingKeyValues.itemTitle: entry.title,
                                  WhooingKeyValues.money: String(entry.money)]
                    
                    self.bookmarkingParams.append(params)
                }
                self.bookmark(self.bookmarkingSlotNumber!)
            }))
        }
        alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Entry {
        if sectionTitles.count == 0 {
            return entries![indexPath.row]
        }
        
        var count = 0
        
        for i in 0..<indexPath.section {
            count += sectionDataCounts[i]
        }
        
        return entries![count + indexPath.row]
    }
    
    func bookmarked(_ resultCode: Int) {
        SVProgressHUD.dismiss()
        
        if resultCode < 0 {
            let alertController = UIAlertController.init(title: NSLocalizedString("입력 실패", comment: "입력 실패"), message: NSLocalizedString("자주입력 거래를 생성하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "입력 실패"), preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                self.bookmark(self.bookmarkingSlotNumber!)
            }))
            alertController.addAction(UIAlertAction.init(title: NSLocalizedString("입력 취소", comment: "입력 취소"), style: .cancel, handler: { action in
                self.bookmarkingParams.removeAll()
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                let parentViewController = parent as! HistoryViewController
                
                parentViewController.cancelTouched(parentViewController.cancelButton)
            }
        }
    }
    
    func bookmark(_ slotNumber: Int) {
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기중"))
        NetworkUtility.postFrequentItems(sectionId: self.sectionId!, slotNumber: slotNumber, params: self.bookmarkingParams, completionHandler: { resultCode in
            self.bookmarked(resultCode)
        })
    }
    
    override func didDeleteSelectedItems(resultCode: Int) {
        super.didDeleteSelectedItems(resultCode: resultCode)
        
        if resultCode < 0 {
            self.entriesNotificationToken = self.entries?.addNotificationBlock({ changes in
                self.refreshSections()
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: - UITableViewDataSource methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! HistoryTableViewCell
        let entry = itemAtIndexPath(indexPath)
        let isMemoEmpty = entry.memo.isEmpty
        
        cell.memoLabel.text = entry.memo
        cell.memoLabel.isHidden = isMemoEmpty
        
        if isMemoEmpty {
            cell.leftBottomSpace.constant = 0
        } else {
            let constraintSize = CGSize.init(width: self.view.frame.size.width - 30, height: .greatestFiniteMagnitude)
            let memoRect = (entry.memo as NSString).boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 13)], context: nil)
            
            cell.leftBottomSpace.constant = 10 + memoRect.size.height
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if mergeArguments == nil {
            super.tableView(tableView, didSelectRowAt: indexPath)
            if !tableView.isEditing {
                let viewController = parent as! HistoryViewController
                
                viewController.entry = itemAtIndexPath(indexPath)
                parent?.performSegue(withIdentifier: "detail", sender: nil)
            }
        } else {
            doneButton.isEnabled = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if mergeArguments != nil {
            if tableView.indexPathsForSelectedRows == nil || tableView.indexPathsForSelectedRows!.count == 0 {
                doneButton.isEnabled = false
            }
        }
    }
    
    // MARK: - Notification handler methods
    
    override func logout() {
        super.logout()
        entriesNotificationToken?.stop()
    }
    
    // MARK: - Action methods
    
    @IBAction func doneTouched(_ sender: Any) {
        selectedIndexPaths = tableView.indexPathsForSelectedRows
        SVProgressHUD.show(withStatus: NSLocalizedString("잠시만 기다려주세요", comment: "대기"))
        
        var money = Double(mergeArguments![WhooingKeyValues.money]!)!
        let firstEntry = itemAtIndexPath(selectedIndexPaths![0])
        
        money += firstEntry.money
        for i in 1..<selectedIndexPaths!.count {
            money += itemAtIndexPath(selectedIndexPaths![i]).money
        }
        entriesNotificationToken?.stop()
        NetworkUtility.postEntry(sectionId: self.sectionId!, leftAccountType: firstEntry.leftAccountType, leftAccountId: firstEntry.leftAccountId, rightAccountType: firstEntry.rightAccountType, rightAccountId: firstEntry.rightAccountId, itemTitle: firstEntry.title, money: String(money), memo: firstEntry.memo, entryDate: String(Int(firstEntry.entryDate)), slotNumber: nil, frequentItemId: nil, completionHandler: { resultCode in
            if resultCode < 0 {
                SVProgressHUD.dismiss()
                
                self.entriesNotificationToken = self.entries?.addNotificationBlock({ changes in
                    self.refreshSections()
                    self.tableView.reloadData()
                })
                let alertController = UIAlertController.init(title: NSLocalizedString("수정 실패", comment: "수정 실패"), message: NSLocalizedString("거래내역을 수정하지 못했습니다. 네트워크 상태를 확인하시고 다시 시도해주세요.", comment: "수정 실패"), preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("다시 시도", comment: "다시 시도"), style: .default, handler: {action in
                    self.doneTouched(self.doneButton)
                }))
                alertController.addAction(UIAlertAction.init(title: NSLocalizedString("취소", comment: "취소"), style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                if NetworkUtility.checkResultCodeWithAlert(resultCode) {
                    self.deleteCall()
                }
            }
        })
    }
}
