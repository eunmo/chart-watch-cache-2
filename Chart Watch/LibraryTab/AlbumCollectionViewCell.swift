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
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var album: AlbumInfo? {
        didSet {
            if let a = album {
                titleLabel.text = a.title
                
                let imageUrl = MusicLibrary.getImageLocalUrl(a.id)
                imageView.image = UIImage(contentsOfFile: imageUrl.path)
            }
        }
    }
    
    var artists: String? {
        didSet {
            artistLabel.text = artists
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        CommonUI.makeMediumLayerCircular(layer: imageView.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
