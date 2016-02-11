//
//  StressTicketTableViewCell.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 08.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//

import UIKit

class StressTicketTableViewCell: UITableViewCell {

    @IBOutlet weak var issuesSummaryLabel: UILabel!
    @IBOutlet weak var assigneeLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var issueTitleLabel: UILabel!
    @IBOutlet weak var stressedImageView: UIImageView!
    
    var stressed = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
