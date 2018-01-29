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
        CommonUI.makeSmallLayerCircular(layer: shuffleImageOuterView.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
