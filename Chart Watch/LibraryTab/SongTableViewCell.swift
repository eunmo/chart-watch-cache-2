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
            titleLabel.text = song?.title
            artistLabel.text = song?.artistString
            playCountLabel.text = "\(song?.plays ?? 0)"
            
            if let id = song?.albumId {
                let imageUrl = MusicLibrary.getImageLocalUrl(id)
                albumView.image = UIImage(contentsOfFile: imageUrl.path)
            }
            
            if let minRank = song?.minRank {
                if minRank == 1 {
                    playCountLabel.backgroundColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1) // apple pink
                } else if minRank <= 5 {
                    playCountLabel.backgroundColor = UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1) // apple purple
                } else {
                    playCountLabel.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1) // apple blue
                }
            } else {
                playCountLabel.backgroundColor = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1) // apple teal blue
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
        makeLayerCircular(layer: albumView.layer)
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
