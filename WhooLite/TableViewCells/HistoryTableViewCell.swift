//
//  HistoryTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 1..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class HistoryTableViewCell: InputBaseTableViewCell {
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var leftBottomSpace: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
