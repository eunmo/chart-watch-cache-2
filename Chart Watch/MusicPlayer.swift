//
//  Player.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/27/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class MusicPlayer: NSObject, AVAudioPlayerDelegate{
    
    var currentSong: FullSong?
    var nextSongs = [FullSong]()
    var player: AVAudioPlayer?
    var library: MusicLibrary?
    
    var isPlaying: Bool {
        get {
            return player?.isPlaying == true
        }
    }
    
    var progress: Float {
        get {
            if let p = player, p.isPlaying {
                return Float(p.currentTime / p.duration)
            } else {
                return 0
            }
        }
    }
    
    var remainingTime: Double? {
        get {
            if let p = player {
                return p.duration - p.currentTime
            } else {
                return nil
            }
        }
    }
    
    static let updateNotificationKey = "PlayerUpdateNotificationKey"
    
    func playNow(_ newSong: FullSong) {
        nextSongs = [newSong]
        
        notify()
        skip()
    }
    
    func addSongs(_ newSongs: [FullSong]) {
        if newSongs.count == 0 {
            return
        }
        
        nextSongs.append(contentsOf: newSongs)
        
        if player?.isPlaying != true {
            playNext()
        }
        notify()
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicPlayer.updateNotificationKey), object: self)
    }
    
    func play() {
        player?.play()
        notify()
    }
    
    func pause() {
        player?.pause()
        notify()
    }
    
    private func getNowPlayingInfo(_ info: FullSong, player: AVAudioPlayer) -> [String: AnyObject] {
        var nowPlayingInfo:[String: AnyObject] = [
            MPMediaItemPropertyTitle: info.title as AnyObject,
            MPMediaItemPropertyArtist: info.artistString as AnyObject,
            MPMediaItemPropertyPlaybackDuration: player.duration as AnyObject,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime as AnyObject,
        ]
        
        if let image = UIImage(contentsOfFile: MusicLibrary.getImageLocalUrl(info.albumId).path){
            let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                return image
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork as AnyObject
        }
        
        return nowPlayingInfo
    }
    
    private func clearPlayer() {
        currentSong = nil
        player = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        notify()
    }
    
    private func playNext() {
        if nextSongs.isEmpty {
            clearPlayer()
            return
        }
        
        let song = nextSongs.remove(at: 0)
        currentSong = song
        notify()
        
        if let player = try? AVAudioPlayer(contentsOf: MusicLibrary.getMediaLocalUrl(song.id)) {
            self.player = player
            player.delegate = self
            player.prepareToPlay()
        
            let nowPlayingInfo = getNowPlayingInfo(song, player: player)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
            play()
        } else {
            clearPlayer()
            notify()
        }
    }
    
    func skip() {
        if let p = player, p.isPlaying {
            p.stop()
        }
        
        playNext()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        library?.recordPlay(currentSong!)
        playNext()
    }
}