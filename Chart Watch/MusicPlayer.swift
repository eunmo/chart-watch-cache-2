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
    var inShuffle = false
    var requestedSongIds = Set<Int>()
    var downloadedSongIds = Set<Int>()
    let shuffleLimit = 10
    
    var isPlaying: Bool {
        get {
            return player?.isPlaying == true
        }
    }
    
    var progress: Float {
        get {
            if let p = player {
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
    
    var hasSomething: Bool {
        get {
            return (currentSong != nil || nextSongs.count > 0)
        }
    }
    
    static let updateNotificationKey = "PlayerUpdateNotificationKey"
    
    func playNow(_ newSong: FullSong) {
        clearPlayer()
        addSongs([newSong])
    }
    
    func addSongs(_ newSongs: [FullSong]) {
        if newSongs.count == 0 {
            return
        }
        
        nextSongs.append(contentsOf: newSongs)
        
        if currentSong == nil {
            playNext()
        } else {
            notify()
        }
    }
    
    func notify() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicPlayer.updateNotificationKey), object: self)
    }
    
    func play() {
        if let player = player {
            let nowPlayingInfo = getNowPlayingInfo(currentSong!, player: player)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            player.play()
        }
        notify()
    }
    
    func pause() {
        if let player = player {
            player.pause()
            let nowPlayingInfo = getNowPlayingInfo(currentSong!, player: player)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
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
        nextSongs = [FullSong]()
        player?.stop()
        player = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        inShuffle = false
        notify()
    }
    
    private func playNext() {
        if nextSongs.isEmpty {
            clearPlayer()
            return
        }
        
        let song = nextSongs.remove(at: 0)
        currentSong = song
        
        if inShuffle {
            addShuffleSongs()
        }
        
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
    
    func skip(recordPlay: Bool) {
        if let p = player, p.isPlaying {
            p.stop()
        }
        
        if let s = currentSong, recordPlay {
            library?.recordPlay(s)
        }
        
        playNext()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        library?.recordPlay(currentSong!)
        playNext()
    }
    
    private func addShuffleSongs() {
        while nextSongs.count < shuffleLimit {
            let newSong = library!.getRandomSong()
            if currentSong?.id != newSong.id && nextSongs.contains(where: { $0.id == newSong.id }) == false {
                nextSongs.append(newSong)
            }
        }
    }
    
    func replaceShuffle() {
        clearPlayer()
        inShuffle = true
        addShuffleSongs()
        playNext()
    }
    
    func addSongsShuffle() {
        inShuffle = true
        addShuffleSongs()
        if currentSong == nil {
            playNext()
        } else {
            notify()
        }
    }
    
    func stopShuffle() {
        inShuffle = false
        notify()
    }
    
    func clearNextSongs() {
        nextSongs = []
        inShuffle = false
        notify()
    }
    
    func removeSong(index: Int) {
        if index < nextSongs.count {
            nextSongs.remove(at: index)
        }
        
        if inShuffle {
            addShuffleSongs()
        }
        
        notify()
    }
    
    func moveSong(from: Int, to: Int) {
        let song = nextSongs.remove(at: from)
        nextSongs.insert(song, at: to)
        
        notify()
    }
    
    func makeLastSong(index: Int) {
        if index < nextSongs.count {
            nextSongs.removeSubrange((index + 1)..<nextSongs.count)
        }
        inShuffle = false
        notify()
    }
    
    func addNetworkSongs(songs: [FullSong]) {
        nextSongs.append(contentsOf: songs)
        if currentSong == nil {
            playNext()
        } else {
            notify()
        }
    }
    
    func addSongsNetworkShuffle() {
        library?.doNetworkShuffle()
    }
    
    func addSongsFromWebView(data: Data) {
        library?.parseThenPlayWebviewSongs(data: data)
    }
}
