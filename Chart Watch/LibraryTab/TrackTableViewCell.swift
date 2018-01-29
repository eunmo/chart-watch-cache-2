//
//  TrackTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/24/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {

    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playCountLabel: UILabel!
    
    var song: FullSong? {
        didSet {
            if let song = song {
                if let track = song.track?.track {
                    trackLabel.text = "\(track)"
                }
                
                titleLabel.text = song.title
                artistLabel.text = song.artistString
                CommonUI.setPlayCountLabel(song: song, label: playCountLabel)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        CommonUI.makeSmallLayerCircular(layer: playCountLabel.layer)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
}
