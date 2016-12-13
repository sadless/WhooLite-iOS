//
//  DatePickerTableViewCell.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 11. 7..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

class DatePickerTableViewCell: UITableViewCell {
    @IBOutlet weak var datePicker: UIDatePicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
