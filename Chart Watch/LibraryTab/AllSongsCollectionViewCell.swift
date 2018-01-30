//
//  AllSongsCollectionViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/30/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class AllSongsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        CommonUI.makeMediumLayerCircular(layer: containerView.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
