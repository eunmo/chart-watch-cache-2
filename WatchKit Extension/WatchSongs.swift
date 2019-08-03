//
//  WatchSongs.swift
//  WatchKit Extension
//
//  Created by Eunmo Yang on 2019/08/03.
//  Copyright © 2019 Eunmo Yang. All rights reserved.
//

import Foundation
import WatchConnectivity


struct WatchSong: Codable {
    let id: Int
    let title: String
    let artists: String
    let plays: Int
}

struct PlayRecord: Codable {
    let id: Int
    let plays: Int
    let lastPlayed: Date
}

struct WatchSongArchive: Codable {
    let songs: [WatchSong]
    let playRecords: [Int: PlayRecord]
    let downloadedSongIds: Set<Int>
}

struct PushData: Codable {
    let id: Int
    let plays: Int
    let lastPlayed: String
}

struct PullData: Codable {
    let id: Int
    let plays: Int
}

class WatchSongs {
    
    var songs = [WatchSong]()
    var songMap = [Int: WatchSong]()
    var playRecords = [Int: PlayRecord]()
    var downloadedSongIds = Set<Int>()
    
    let dateFormatter: DateFormatter = DateFormatter()
    let decoder: JSONDecoder
    
    let serverAddress = "http://13.230.33.104:3010"
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("watchsongs")
    static let notificationKey = "WatchSongsNotificationKey"
    
    static func getMediaLocalUrl(_ id: Int) -> URL {
        return WatchSongs.DocumentsDirectory.appendingPathComponent("\(id).mp3")
    }
    
    init() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func getStatus() -> (Int, Int, Int) {
        let songCount = songs.count
        let savedSongs = getSavedSongs().count
        let played = playRecords.count
        
        return (songCount, savedSongs, played)
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
        let archive = WatchSongArchive(songs: songs, playRecords: playRecords, downloadedSongIds: downloadedSongIds)
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
            playRecords = archive.playRecords
            downloadedSongIds = archive.downloadedSongIds
            buildMaps()
        }
        
        //deleteAllFiles()
    }
    
    func buildMaps() {
        songMap = [Int: WatchSong]()
        for song in songs {
            songMap[song.id] = song
        }
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
            
            downloadedSongIds.removeAll()
            save()
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
    
    func recordPlay(_ song: WatchSong) {
        let id = song.id
        
        let playCount = max(song.plays, songMap[id]?.plays ?? 0, playRecords[id]?.plays ?? 0) + 1
        playRecords[id] = PlayRecord(id: id, plays: playCount, lastPlayed: Date())
        
        save()
    }
    
    func getPushData() -> [PushData] {
        var data = [PushData]()
        
        for (id, record) in playRecords {
            data.append(PushData(id: id, plays: record.plays, lastPlayed: dateFormatter.string(from: record.lastPlayed)))
        }
        
        return data
    }

    func updatePlays(_ data: Data) {
        do {
            let json = try decoder.decode([PullData].self, from: data)
            
            for data in json {
                if let record = playRecords[data.id] {
                    if record.plays <= data.plays {
                        playRecords[data.id] = nil
                    }
                }
            }
            
            save()
        } catch {
            print(error)
        }
    }
    
    func syncPlays() {
        let pushData = getPushData()
        
        if pushData.count == 0 {
            return
        }
        
        if let data = try? JSONEncoder().encode(pushData) {
            
            let urlAsString = "\(serverAddress)/ios/plays/sync"
            let url = URL(string: urlAsString)!
            let urlSession = URLSession.shared
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
                if let d = data {
                    self.updatePlays(d)
                }
            })
            task.resume()
        }
    }
}
