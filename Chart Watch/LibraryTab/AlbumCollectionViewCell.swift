//
//  AlbumCollectionViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var album: Album? {
        didSet {
            titleLabel.text = album?.title
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
