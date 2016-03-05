//
//  DownloadCellTableViewCell.swift
//  testUseNetKit
//
//  Created by tanson on 16/3/5.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class DownloadCellTableViewCell: UITableViewCell {

    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var progress: UILabel!
    @IBOutlet weak var cureentSize: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
