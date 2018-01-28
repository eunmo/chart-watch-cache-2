//
//  SongTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/23/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumView: UIImageView!
    
    var song: FullSong? {
        didSet {
            titleLabel.text = song?.title
            artistLabel.text = song?.artistString
            
            if let id = song?.albumId {
                let imageUrl = MusicLibrary.getImageLocalUrl(id)
                albumView.image = UIImage(contentsOfFile: imageUrl.path)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        let layer = albumView.layer
        layer.masksToBounds = true
        layer.cornerRadius = CGFloat(10)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
