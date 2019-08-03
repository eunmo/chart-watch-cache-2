//
//  WatchSongs.swift
//  WatchKit Extension
//
//  Created by Eunmo Yang on 2019/08/03.
//  Copyright © 2019 Eunmo Yang. All rights reserved.
//

import Foundation
import AVFoundation
import WatchConnectivity


struct WatchSong: Codable {
    let id: Int
    let title: String
    let artists: String
    let plays: Int
}

struct WatchSongArchive: Codable {
    let songs: [WatchSong]
    let downloadedSongIds: Set<Int>
}

class WatchSongs {
    
    var songs = [WatchSong]()
    var downloadedSongIds = Set<Int>()
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("watchsongs")
    static let notificationKey = "WatchSongsNotificationKey"
    
    static func getMediaLocalUrl(_ id: Int) -> URL {
        return WatchSongs.DocumentsDirectory.appendingPathComponent("\(id).mp3")
    }
    
    func getStatus() -> (Int, Int, Int) {
        let songCount = songs.count
        let savedSongs = getSavedSongs().count
        let extra = downloadedSongIds.count - savedSongs
        
        return (songCount, savedSongs, extra)
    }
    
    func getSavedSongs() -> [WatchSong] {
        return songs.filter({ downloadedSongIds.contains($0.id) })
    }
    
    func getRandomSavedSong() -> WatchSong? {
        let songs = getSavedSongs()
        
        if songs.count == 0 {
            return nil
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(songs.count)))
        return songs[randomIndex]
    }
    
    func parseSongList(_ list: [[String: Any]]) {
        var songs = [WatchSong]()
        for song in list {
            let id = song["id"] as! Int
            let title = song["title"] as! String
            let artists = song["artists"] as! String
            let plays = song["plays"] as! Int
            songs.append(WatchSong(id: id, title: title, artists: artists, plays: plays))
        }
        self.songs = songs
        save()
    }
    
    func getSongIdsToRequest() -> [Int] {
        var ids = [Int]()
        
        for song in songs {
            if downloadedSongIds.contains(song.id) == false {
                ids.append(song.id)
            }
        }
        
        return ids
    }
    
    func save() {
        let archive = WatchSongArchive(songs: songs, downloadedSongIds: downloadedSongIds)
        let encoded = try! PropertyListEncoder().encode(archive)
        let data = try! NSKeyedArchiver.archivedData(withRootObject: encoded, requiringSecureCoding: false)
        try! data.write(to: WatchSongs.ArchiveURL)
        NotificationCenter.default.post(name: Notification.Name(rawValue: WatchSongs.notificationKey), object: self)
    }
    
    func load() {
        if let data = try? Data(contentsOf: WatchSongs.ArchiveURL),
            let archived = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data,
            let archive = try? PropertyListDecoder().decode(WatchSongArchive.self, from: archived) {
            songs = archive.songs
            downloadedSongIds = archive.downloadedSongIds
        }
        
        //deleteAllFiles()
    }
    
    private func deleteAllFiles() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: WatchSongs.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
            
            for file in files {
                switch file.pathExtension {
                case "mp3":
                    try FileManager.default.removeItem(at: file)
                default:
                    break
                }
            }
        } catch {
        }
    }
    
    private func moveFile(at: URL, to: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: at, to: to)
        } catch {
            return false
        }
        
        return true
    }
    
    func saveFile(_ file: WCSessionFile) {
        let id = file.metadata!["id"] as! Int
        let localUrl = WatchSongs.getMediaLocalUrl(id)
        
        if moveFile(at: file.fileURL, to: localUrl) {
            downloadedSongIds.insert(id)
            save()
        }
    }
}
