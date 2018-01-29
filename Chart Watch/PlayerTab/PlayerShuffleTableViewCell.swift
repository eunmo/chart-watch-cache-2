//
//  PlayerShuffleTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/29/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class PlayerShuffleTableViewCell: UITableViewCell {

    @IBOutlet weak var shuffleImageOuterView: UIView!
    @IBOutlet weak var shuffleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        shuffleImageOuterView.layer.masksToBounds = true
        shuffleImageOuterView.layer.cornerRadius = 17.5
        shuffleImageOuterView.layer.borderWidth = 0.5
        shuffleImageOuterView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
