//
//  SongTableViewHeaderView.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/26/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class SongTableViewHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!
    
    var album: AlbumS? {
        didSet {
            if let a = album {
                titleLabel.text = a.title
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                dateFormatter.locale = Locale(identifier: "en_US")
                releaseLabel.text = "\(dateFormatter.string(from: a.release))"
                
                let imageUrl = MusicLibrary.getImageLocalUrl(a.id)
                let image = UIImage(contentsOfFile: imageUrl.path)
                imageView.image = image
            }
        }
    }
    
    var artists: String? {
        didSet {
            artistLabel.text = artists
        }
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
