//
//  SelectTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 8. 7..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class SelectableTableViewCell: UITableViewCell {
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
