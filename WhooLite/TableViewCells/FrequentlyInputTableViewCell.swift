//
//  FrequentlyInputTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 24..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class FrequentlyInputTableViewCell: InputBaseTableViewCell {
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
