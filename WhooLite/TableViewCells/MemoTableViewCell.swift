//
//  TextViewTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 9. 16..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class MemoTableViewCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let toolbar = UIToolbar.init()
        
        toolbar.items = [UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                         UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(doneTouched))]
        toolbar.sizeToFit()
        textView.inputAccessoryView = toolbar
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func doneTouched(_ sender: AnyObject) {
        textView.resignFirstResponder()
    }
}
