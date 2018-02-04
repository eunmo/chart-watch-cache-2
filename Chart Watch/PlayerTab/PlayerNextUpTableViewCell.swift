//
//  PlayerNextUpTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 2/4/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class PlayerNextUpTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var count: Int? {
        didSet {
            if let count = count {
                titleLabel.text = "Next Up: \(count == 1 ? "" : "\(count) Songs")"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
}
