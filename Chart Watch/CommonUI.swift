//
//  CommonUI.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/29/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class CommonUI {
    static let pink = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
    static let purple = UIColor(red: 88/255, green: 86/255, blue: 214/255, alpha: 1)
    static let blue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
    static let tealBlue = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1)
    
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
                label.backgroundColor = CommonUI.pink
            } else if minRank <= 5 {
                label.backgroundColor = CommonUI.purple
            } else {
                label.backgroundColor = CommonUI.blue
            }
        } else {
            label.backgroundColor = CommonUI.tealBlue
        }
    }
}
