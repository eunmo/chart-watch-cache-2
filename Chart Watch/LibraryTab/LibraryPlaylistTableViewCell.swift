//
//  LibraryPlaylistTableViewCell.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/27/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class LibraryPlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageView5: UIImageView!
    @IBOutlet weak var imageView6: UIImageView!
    @IBOutlet weak var imageView7: UIImageView!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var albumIds: [Int]? {
        didSet {
            let imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6, imageView7]
            
            for imageView in imageViews {
                imageView?.image = nil
            }
            
            for (index, id) in (albumIds?.enumerated())! {
                if index >= imageViews.count {
                    break
                }
                
                let imageUrl = MusicLibrary.getImageLocalUrl(id)
                imageViews[index]?.image = UIImage(contentsOfFile: imageUrl.path)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6, imageView7]
        
        for imageView in imageViews {
            if let layer = imageView?.layer {
                CommonUI.makeSmallLayerCircular(layer: layer)
            }
        }
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
