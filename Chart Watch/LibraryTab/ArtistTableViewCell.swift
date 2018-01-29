//
//  ArtistTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class ArtistTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var albumView: UIImageView!
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    
    var album: AlbumInfo? {
        didSet {
            if let a = album {
                let imageUrl = MusicLibrary.getImageLocalUrl(a.id)
                albumView.image = UIImage(contentsOfFile: imageUrl.path)
            } else {
                albumView.image = nil
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        CommonUI.makeSmallLayerCircular(layer: albumView.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
