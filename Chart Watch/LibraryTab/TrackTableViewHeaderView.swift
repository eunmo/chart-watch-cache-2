//
//  SongTableViewHeaderView.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/26/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class TrackTableViewHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!
    
    var album: AlbumInfo? {
        didSet {
            if let a = album {
                titleLabel.text = a.title
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale(identifier: "en_US")
                releaseLabel.text = "\(dateFormatter.string(from: a.release))"
                
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
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = CGFloat(20)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
