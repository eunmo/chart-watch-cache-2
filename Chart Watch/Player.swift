//
//  Player.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/27/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation

class Player {
    var playing = false
    var currentSong: FullSong?
    var nextSongs = [FullSong]()
    
    static let updateNotificationKey = "PlayerUpdateNotificationKey"
    
    func playNow(_ newSong: FullSong) {
        nextSongs = [FullSong]()
        currentSong = newSong
        
        notify()
    }
    
    func addSongs(_ newSongs: [FullSong]) {
        if newSongs.count == 0 {
            return
        }
        
        nextSongs.append(contentsOf: newSongs)
        
        if currentSong == nil {
            currentSong = nextSongs.remove(at: 0)
        }
        
        notify()
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Player.updateNotificationKey), object: self)
    }
}
