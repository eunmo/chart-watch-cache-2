//
//  LibraryArtistInitialCollectionViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class LibraryArtistInitialCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var initialLabel: UILabel!
    
    var initial: Character? {
        didSet {
            initialLabel.text = "\(initial!)"
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
