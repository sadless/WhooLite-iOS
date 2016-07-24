//
//  InputBaseTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 25..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class InputBaseTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var moneyLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
