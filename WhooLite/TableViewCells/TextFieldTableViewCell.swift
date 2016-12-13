//
//  TextFieldTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 8. 5..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

protocol TextFieldTableViewCellDelegate {
    func didPrevTouch(_ cell: TextFieldTableViewCell)
    func didNextTouch(_ cell: TextFieldTableViewCell)
    func didReturnKeyTouch(_ cell: TextFieldTableViewCell)
}

class TextFieldTableViewCell: UITableViewCell {
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    var delegate: TextFieldTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let toolbar = UIToolbar.init()
        
        toolbar.items = [UIBarButtonItem.init(title: NSLocalizedString("이전", comment: "이전"), style: .plain, target: self, action: #selector(prevTouched)),
                         UIBarButtonItem.init(title: NSLocalizedString("다음", comment: "다음"), style: .plain, target: self, action: #selector(nextTouched)),
                         UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                         UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(doneTouched))]
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
        textField.addTarget(self, action: #selector(returnKeyTouched), for: .editingDidEndOnExit)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Instance methods
    
    func prevTouched(_ sender: AnyObject) {
        delegate?.didPrevTouch(self)
    }
    
    func nextTouched(_ sender: AnyObject) {
        delegate?.didNextTouch(self)
    }
    
    func doneTouched(_ sender: AnyObject) {
        textField.resignFirstResponder()
    }
    
    func returnKeyTouched(_ sender: AnyObject) {
        delegate?.didReturnKeyTouch(self)
    }
}
