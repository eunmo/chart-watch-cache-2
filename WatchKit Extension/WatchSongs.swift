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
}

class WatchSongs {
    
    var songs = [WatchSong]()
    var downloadedSongIds = Set<Int>()
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("watchsongs")
    
    func parseSongList(_ reply: [String: Any]) {
        if let value = reply["songs"] {
            let array = value as! [[String: Any]]
            var songs = [WatchSong]()
            for song in array {
                let id = song["id"] as! Int
                let title = song["title"] as! String
                let artists = song["artists"] as! String
                let plays = song["plays"] as! Int
                songs.append(WatchSong(id: id, title: title, artists: artists, plays: plays))
            }
            self.songs = songs
            save()
            getFile(id: songs[0].id)
            getFile(id: songs[1].id)
        }
    }
    
    func getFile(id: Int) {
        let session = WCSession.default
        session.sendMessage(["request": "song", "id": id], replyHandler: nil)
    }
    
    func save() {
        let archive = WatchSongArchive(songs: songs)
        let encoded = try! PropertyListEncoder().encode(archive)
        let data = try! NSKeyedArchiver.archivedData(withRootObject: encoded, requiringSecureCoding: false)
        try! data.write(to: WatchSongs.ArchiveURL)
    }
    
    func load() {
        if let data = try? Data(contentsOf: WatchSongs.ArchiveURL),
            let archived = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data,
            let archive = try? PropertyListDecoder().decode(WatchSongArchive.self, from: archived) {
            songs = archive.songs
        }
    }
}
