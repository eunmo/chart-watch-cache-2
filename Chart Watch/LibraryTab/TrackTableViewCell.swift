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
            titleLabel.text = song?.title
            artistLabel.text = song?.artistString
            playCountLabel.text = "\(song?.plays ?? 0)"
            
            if let track = song?.track?.track {
                trackLabel.text = "\(track)"
            }
        }
    }
    
    func makeLayerCircular(layer: CALayer) {
        layer.masksToBounds = true
        layer.cornerRadius = 17.5
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        playCountLabel.backgroundColor = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1) // apple teal blue
        makeLayerCircular(layer: playCountLabel.layer)
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
