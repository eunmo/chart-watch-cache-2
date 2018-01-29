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
    @IBOutlet weak var playCountLabel: UILabel!
    
    var song: FullSong? {
        didSet {
            if let song = song {
                titleLabel.text = song.title
                artistLabel.text = song.artistString
                CommonUI.setPlayCountLabel(song: song, label: playCountLabel)
                albumView.image = UIImage(contentsOfFile: MusicLibrary.getImageLocalUrl(song.albumId).path)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        CommonUI.makeSmallLayerCircular(layer: playCountLabel.layer)
        CommonUI.makeSmallLayerCircular(layer: albumView.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
