//
//  WatchPlayer.swift
//  WatchKit Extension
//
//  Created by Eunmo Yang on 2019/08/03.
//  Copyright © 2019 Eunmo Yang. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class WatchPlayer: NSObject, AVAudioPlayerDelegate {

    var currentSong: WatchSong?
    var player: AVAudioPlayer?
    var library: WatchSongs?
    
    var isPlaying: Bool {
        get {
            return player?.isPlaying == true
        }
    }
    
    static let notificationKey = "PlayerNotificationKey"
    
    private func getNowPlayingInfo(_ info: WatchSong, player: AVAudioPlayer) -> [String: AnyObject] {
        let nowPlayingInfo:[String: AnyObject] = [
            MPMediaItemPropertyTitle: info.title as AnyObject,
            MPMediaItemPropertyArtist: info.artists as AnyObject,
            MPMediaItemPropertyPlaybackDuration: player.duration as AnyObject,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime as AnyObject,
        ]
        
        return nowPlayingInfo
    }
    
    func play() {
        if let player = player {
            let nowPlayingInfo = getNowPlayingInfo(currentSong!, player: player)
            AVAudioSession.sharedInstance().activate(options: []) { (success, error) in
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                player.play()
                print("playing \(nowPlayingInfo)!")
            }
        }
    }
    
    func pause() {
        if let player = player {
            player.pause()
            let nowPlayingInfo = getNowPlayingInfo(currentSong!, player: player)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func clearPlayer() {
        currentSong = nil
        player?.stop()
        player = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func playNext() {
        if let song = library?.getRandomSavedSong() {
            playSong(song)
        }
    }
    
    func playSong(_ song: WatchSong) {
        clearPlayer()
        print("play \(song)")
        if let player = try? AVAudioPlayer(contentsOf: WatchSongs.getMediaLocalUrl(song.id)) {
            print("playing \(song)")
            currentSong = song
            self.player = player
            player.delegate = self
            player.prepareToPlay()
            
            let nowPlayingInfo = getNowPlayingInfo(song, player: player)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            play()
        } else {
            clearPlayer()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        library?.recordPlay(currentSong!)
        playNext()
    }
}
