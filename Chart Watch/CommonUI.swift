//
//  CommonUI.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/29/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class CommonUI {
    static func makeSmallLayerCircular(layer: CALayer) {
        layer.masksToBounds = true
        layer.cornerRadius = 17.5
    }
    
    static func makeMediumLayerCircular(layer: CALayer) {
        layer.masksToBounds = true
        layer.cornerRadius = 17.5
    }
    
    static func setPlayCountLabel(song: FullSong, label: UILabel) {
        label.text = "\(song.plays)"
        
        if let minRank = song.minRank {
            if minRank == 1 {
                label.backgroundColor = UIColor.systemPink
            } else if minRank <= 5 {
                label.backgroundColor = UIColor.systemIndigo
            } else {
                label.backgroundColor = UIColor.systemBlue
            }
        } else {
            label.backgroundColor = UIColor.systemGray
        }
    }
}
