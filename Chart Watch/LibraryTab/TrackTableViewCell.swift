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
    
    var song: FullSong? {
        didSet {
            titleLabel.text = song?.title
            artistLabel.text = song?.artistString
            
            if let track = song?.track?.track {
                trackLabel.text = "\(track)"
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
