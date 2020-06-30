//
//  MusicLibrary.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/21/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class MusicLibrary {
    
    // MARK: raw data
    
    var songs = [Song]()
    var albums = [Album]()
    var artists = [Artist]()
    var playlists = [Playlist]()
    var playRecords = [Int: PlayRecord]()
    
    // MARK: indexed map
    
    var songMap = [Int: Song]()
    var albumMap = [Int: Album]()
    var artistMap = [Int: Artist]()
    var artistAlbums = [Int: [Int]]()
    var songAlbums = [Int: [Int]]()
    var initials = [Character: [Artist]]()
    
    // MARK: set
    
    var downloadedMedia = Set<Int>()
    var downloadedImage = Set<Int>()
    
    let downloader = Downloader()
    var player: MusicPlayer?
    
    let dateFormatter: DateFormatter = DateFormatter()
    let decoder: JSONDecoder
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("library")
    static let notificationKey = "MusicPlayerNotificationKey"
    static let notificationKeyCleanUpDone = "MusicPlayerNotificationKey - CleanUp"
    static let notificationKeyDeleteImagesDone = "MusicPlayerNotificationKey - DeleteImages"
    static let notificationKeyCheckDownloadsDone = "MusicPlayerNotificationKey - CheckDownloads"
    
    init() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        for char in Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            initials[char] = [Artist]()
        }
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func save() {
        let archive = Archive(songs: songs, albums: albums, artists: artists, playlists: playlists, playRecords: playRecords, downloadedMedia: downloadedMedia, downloadedImage: downloadedImage)
        let data = try! PropertyListEncoder().encode(archive)
        NSKeyedArchiver.archiveRootObject(data, toFile: MusicLibrary.ArchiveURL.path)
    }
    
    func load() {
        if let data = NSKeyedUnarchiver.unarchiveObject(withFile: MusicLibrary.ArchiveURL.path) as? Data {
            if let archive = try? PropertyListDecoder().decode(Archive.self, from: data) {
                songs = archive.songs
                albums = archive.albums
                artists = archive.artists
                playlists = archive.playlists
                playRecords = archive.playRecords
                downloadedMedia = archive.downloadedMedia
                downloadedImage = archive.downloadedImage
                buildMaps()
            }
        }
    }
    
    func buildMaps() {
        songMap = [Int: Song]()
        songAlbums = [:]
        for song in songs {
            songMap[song.id] = song
            songAlbums[song.id] = [Int]()
        }
        
        albumMap = [Int: Album]()
        for album in albums {
            albumMap[album.info.id] = album
        }
        
        artistMap = [Int: Artist]()
        artistAlbums = [:]
        for artist in artists {
            artistMap[artist.id] = artist
            artistAlbums[artist.id] = [Int]()
        }
        
        for album in albums {
            for artist in album.info.artists {
                artistAlbums[artist]!.append(album.id)
            }
            for track in album.info.tracks {
                songAlbums[track.id]!.append(album.id)
            }
        }
        
        for (key, _) in initials {
            initials[key] = [Artist]()
        }
        
        var initial: Character
        for artist in artists {
            initial = getInitial(name: artist.nameNorm)
            initials[initial]?.append(artist)
        }
        
        for (key, array) in initials {
            initials[key] = array.sorted(by: {
                let album0 = artistAlbums[$0.id]!.count
                let album1 = artistAlbums[$1.id]!.count
                
                if album0 * album1 > 0 {
                    return $0.nameNorm.lowercased() < $1.nameNorm.lowercased()
                } else {
                    return album0 > album1
                }
            })
        }
        
        for (key, array) in songAlbums {
            songAlbums[key] = array.sorted(by: { (a, b) -> Bool in
                return albumMap[a]!.info.release > albumMap[b]!.info.release
            })
        }
    }
    // MARK: URLs
    
    static func getImageLocalUrl(_ id: Int) -> URL {
        return MusicLibrary.DocumentsDirectory.appendingPathComponent("\(id).jpg")
    }
    
    static func getMediaLocalUrl(_ id: Int) -> URL {
        return MusicLibrary.DocumentsDirectory.appendingPathComponent("\(id).mp3")
    }
    
    // MARK: Initiate Downloads
    
    func startDownload(albums: [Int], songs: [Int]) {
        for albumId in albums {
            if downloadedImage.contains(albumId) == false {
                downloader.requestImage(id: albumId, callback: { (done: Bool) -> Void in
                    self.downloadedImage.insert(albumId)
                    
                    if done {
                        self.save()
                    }
                })
            }
        }
        
        for songId in songs {
            if downloadedMedia.contains(songId) == false {
                downloader.requestMedia(id: songId, callback: { (done: Bool) -> Void in
                    self.downloadedMedia.insert(songId)
                    
                    if done {
                        self.save()
                    }
                })
            }
        }
    }
    
    func doCheckDownloads() {
        var albums = [Int]()
        for (_, album) in downloadedImage.enumerated() {
            let image = UIImage(contentsOfFile: MusicLibrary.getImageLocalUrl(album).path)
            if image == nil {
                albums.append(album)
            }
        }
        
        var songs = [Int]()
        for (index, song) in downloadedMedia.enumerated() {
            let player = try? AVAudioPlayer(contentsOf: MusicLibrary.getMediaLocalUrl(song))
            if player == nil {
                songs.append(song)
            }
            
            if index % 1000 == 0 {
                print(index)
            }
        }
        
        save()
        startDownload(albums: albums, songs: songs)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKeyCheckDownloadsDone), object: self)
    }
    
    // MARK: Handle Initials
    
    func getInitial(name: String) -> Character {
        var regex: NSRegularExpression
        
        for char in Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            regex = try! NSRegularExpression(pattern: "^\(char)", options: NSRegularExpression.Options.caseInsensitive)
            if regex.matches(in: name, options: [], range: NSRange(name.startIndex..., in: name)).count > 0 {
                return char
            }
        }
        
        let leftString = "가나다라마바사아자차카타파"
        let rightString = "나다라마바사아자차카타파하"
        
        for index in leftString.indices {
            if name >= "\(leftString[index])" && name < "\(rightString[index])" {
                return "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍ"[index]
            }
        }
        
        if name >= "하" {
            return "ㅎ".first!
        }
        
        return "#".first!
    }
    
    func getArtistsByInitial(initial: Character) -> [ArtistInfo] {
        return initials[initial]!.map({ $0.info })
    }
    
    func getInitialCount(initial: Character) -> Int {
        return initials[initial]!.count
    }
    
    func getAllAlbums() -> [AlbumInfo] {
        var albums = [AlbumInfo]()
        
        for album in self.albums {
            albums.append(album.info)
        }
        
        return albums
    }
    
    func getLatestAlbum(by artist: ArtistInfo) -> AlbumInfo? {
        let albumIds = artistAlbums[artist.id]!
        var albums = [AlbumInfo]()
        
        for albumId in albumIds {
            albums.append(albumMap[albumId]!.info)
        }
        
        if (albums.count > 0) {
            albums.sort(by: { $0.release > $1.release })
            return albums[0]
        }
        
        return nil
    }
    
    func getAlbumsByArtist(artist: ArtistInfo) -> [AlbumInfo] {
        var albumIdSet = Set<Int>()
        
        for album in albums {
            if album.info.artists.contains(artist.id) {
                albumIdSet.insert(album.id)
            }
        }
        
        for song in songs {
            if song.info.artists.contains(artist.id) || song.info.features.contains(artist.id) {
                for album in albums {
                    for track in album.info.tracks {
                        if track.id == song.id {
                            albumIdSet.insert(album.id)
                        }
                    }
                }
            }
        }
        
        var artistAlbums = [AlbumInfo]()
        
        for albumId in albumIdSet {
            artistAlbums.append(albumMap[albumId]!.info)
        }
        
        return artistAlbums
    }
    
    func getAlbumArtistString(id: Int) -> String {
        let album = albumMap[id]!
        
        var artistString = ""
        for artistId in album.info.artists {
            let artist = artistMap[artistId]!
            artistString += (artistString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        
        return artistString
    }
    
    func makeFullSong(song: SongInfo, track: Track? = nil, album: AlbumInfo? = nil) -> FullSong {
        var artist: ArtistInfo
        
        var artistString = ""
        for artistId in song.artists {
            artist = artistMap[artistId]!.info
            artistString += (artistString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        
        var featureString = ""
        for artistId in song.features {
            artist = artistMap[artistId]!.info
            featureString += (featureString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        if featureString != "" {
            artistString += " feat. \(featureString)"
        }
        
        let songAlbum = album != nil ? album : albumMap[songAlbums[song.id]![0]]!.info
        
        let fullSong = FullSong(id: song.id, title: song.title, artistString: artistString, albumId: songAlbum!.id, plays: song.plays, minRank: song.minRank, track: track, fromNetwork: false)
        
        return fullSong
    }
    
    func getSongs() -> [FullSong] {
        var fullSongs = [FullSong]()
        
        for song in songs {
            fullSongs.append(makeFullSong(song: song.info))
        }
        
        return fullSongs
    }
    
    func sortByTracks(songA: FullSong, songB: FullSong) -> Bool {
        let a = songA.track!
        let b = songB.track!
        
        return a.disk != b.disk ? a.disk < b.disk : a.track < b.track
    }
    
    func getSongs(by album: AlbumInfo) -> [FullSong] {
        var albumSongs = [FullSong]()
        
        for track in album.tracks {
            albumSongs.append(makeFullSong(song: songMap[track.id]!.info, track: track, album: album))
        }
        
        albumSongs.sort(by: sortByTracks)
        
        return albumSongs
    }
    
    func getSongs(by album: AlbumInfo, filterBy artist: ArtistInfo) -> [FullSong] {
        
        if album.artists.contains(artist.id) {
            return getSongs(by: album)
        } else {
            var albumSongs = [FullSong]()
            
            for track in album.tracks {
                let song = songMap[track.id]!
                
                if song.info.artists.contains(artist.id) || song.info.features.contains(artist.id) {
                    albumSongs.append(makeFullSong(song: song.info, track: track, album: album))
                }
            }
            
            albumSongs.sort(by: sortByTracks)
            
            return albumSongs
        }
    }
    
    func getSongPlaylistFromAlbumPlaylist(_ albumPlaylist: Playlist) -> Playlist {
        let name = "Songs in \(albumPlaylist.name)"
        var songIds = [Int]()
        
        if albumPlaylist.playlistType == .albumPlaylist {
            for albumId in albumPlaylist.list {
                for track in albumMap[albumId]!.info.tracks {
                    songIds.append(track.id)
                }
            }
        }
        
        return Playlist(playlistType: .songPlaylist, name: name, list: songIds)
    }
    
    func getAritstPlaylist(artist: ArtistInfo) -> Playlist {
        var albums = getAlbumsByArtist(artist: artist)
        albums.sort(by: { $0.release > $1.release })
        
        var songIds = [Int]()
        var songIdSet = Set<Int>()
        
        for album in albums {
            let albumSongs = getSongs(by: album, filterBy: artist)
            for song in albumSongs {
                if songIdSet.contains(song.id) == false {
                    songIds.append(song.id)
                    songIdSet.insert(song.id)
                }
            }
        }
        
        return Playlist(playlistType: .songPlaylist, name: "Songs by \(artist.name)", list: songIds)
    }
    
    func getPlaylistAlbumIds(_ playlist: Playlist) -> [Int] {
        if playlist.playlistType == .albumPlaylist {
            return playlist.list
        }
        
        var albums = [Int]()
        
        for songId in playlist.list {
            var albumId: Int?
            
            if let songAlbums = songAlbums[songId] {
                albumId = songAlbums[0]
            } else if let record = playRecords[songId] {
                albumId = record.fullSong.albumId
            }
            
            if let albumId = albumId, albums.last != albumId {
                albums.append(albumId)
            }
        }
        
        return albums
    }
    
    func getPlaylistAlbums(_ playlist: Playlist) -> [AlbumInfo] {
        if playlist.playlistType != .albumPlaylist {
            return [AlbumInfo]()
        }
        
        var albums = [AlbumInfo]()
        
        for albumId in playlist.list {
            albums.append(albumMap[albumId]!.info)
        }
        
        return albums
    }
    
    func getPlaylistSongs(_ playlist: Playlist) -> [FullSong] {
        if playlist.playlistType != .songPlaylist {
            return [FullSong]()
        }
        
        var playlistSongs = [FullSong]()
        
        for songId in playlist.list {
            if let song = songMap[songId] {
                playlistSongs.append(makeFullSong(song: song.info))
            } else if let record = playRecords[songId] {
                playlistSongs.append(record.fullSong)
            }
        }
        
        return playlistSongs
    }
    
    func getLocallyPlayedPlaylist() -> Playlist {
        var locallyPlayed = Array(playRecords.values.map({ $0 }))
        locallyPlayed.sort(by: { $0.lastPlayed < $1.lastPlayed })
        return Playlist(playlistType: .songPlaylist, name: "Locally Played", list: locallyPlayed.map({ $0.id }))
    }
    
    func getPlaylists() -> [Playlist] {
        var newArray = [Playlist]()
        
        let locallyPlayed = getLocallyPlayedPlaylist()
        if locallyPlayed.list.count > 0 {
            newArray.append(getLocallyPlayedPlaylist())
            newArray.append(contentsOf: playlists)
            return newArray
        }
        
        return playlists
    }
    
    func recordPlay(_ fullSong: FullSong) -> PlayRecord {
        let id = fullSong.id
        
        let newPlayCount = max(fullSong.plays, songMap[id]?.info.plays ?? 0, playRecords[id]?.plays ?? 0) + 1
        var newFullSong = fullSong
        newFullSong.plays = newPlayCount
        let newRecord = PlayRecord(id: id, fullSong: newFullSong, plays: newPlayCount, lastPlayed: Date())
        playRecords[id] = newRecord
        
        if let song = songMap[id] {
            updatePlay(song: song, playCount: newPlayCount)
        }
        
        save()
        doSync()
        notifyUpdate()
        
        return newRecord
    }
    
    func getPushData() -> [PushData] {
        var data = [PushData]()
        
        for (id, record) in playRecords {
            data.append(PushData(id: id, plays: record.plays, lastPlayed: dateFormatter.string(from: record.lastPlayed)))
        }
        
        return data
    }
    
    func doSync() {
        downloader.sync(pushData: getPushData(), completion: updatePlays)
    }
    
    func notifyUpdate() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKey), object: self)
    }
    
    func updateSongInfoPlays(songInfo: SongInfo, plays: Int) -> SongInfo {
        var newInfo = songInfo
        newInfo.plays = plays
        return newInfo
    }
    
    func updatePlay(song: Song, playCount: Int) {
        song.info = updateSongInfoPlays(songInfo: song.info, plays: playCount)
    }
    
    func updatePlays(data: Data) {
        do {
            let json = try decoder.decode([PullData].self, from: data)
            
            for data in json {
                if let song = songMap[data.id] {
                    if song.info.plays != data.plays {
                        updatePlay(song: song, playCount: data.plays)
                    }
                }
                
                if let record = playRecords[data.id] {
                    if record.plays <= data.plays {
                        playRecords[data.id] = nil
                    }
                }
            }
            
            save()
            notifyUpdate()
        } catch {
            print("\(error)")
        }
    }
    
    func normalizeString(string: String) -> String {
        return string.replacingOccurrences(of: "`", with: "'")
    }
    
    func addPlaylists(json: ServerJSON) {
        playlists = [Playlist]()
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Current Singles", list: json.singleCharts))
        playlists.append(Playlist(playlistType: .albumPlaylist, name: "Current Albums", list: json.albumCharts))
        
        if (json.newAlbums.count > 0) {
            playlists.append(Playlist(playlistType: .albumPlaylist, name: "New Albums", list: json.newAlbums))
        }
        
        playlists.append(Playlist(playlistType: .albumPlaylist, name: "Favorite Artists", list: json.favorites))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Seasonal Songs", list: json.seasonal))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Charted Songs", list: json.charted))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Unfamiliar Songs", list: json.uncharted))
    }
    
    func expandIds(condensed: [[Int]]) -> [Int] {
        var array = [Int]()
        
        for pair in condensed {
            for i in pair[0]...pair[1] {
                array.append(i)
            }
        }
        
        return array
    }
    
    func replaceData(data: Data) -> Bool {
        do {
            let json = try decoder.decode(ServerJSON.self, from: data)
            
            songs = [Song]()
            for var songInfo in json.songs {
                songInfo.title = self.normalizeString(string: songInfo.title)
                songInfo.plays = max(songInfo.plays, playRecords[songInfo.id]?.plays ?? 0)
                songs.append(Song(info: songInfo))
            }
            
            albums = [Album]()
            for var albumInfo in json.albums {
                albumInfo.title = self.normalizeString(string: albumInfo.title)
                albums.append(Album(info: albumInfo))
            }
            
            artists = [Artist]()
            for var artistInfo in json.artists {
                artistInfo.name = self.normalizeString(string: artistInfo.name)
                artists.append(Artist(info: artistInfo))
            }
            
            addPlaylists(json: json)
            
            let songIds = expandIds(condensed: json.songIds)
            let albumIds = expandIds(condensed: json.albumIds)
            startDownload(albums: albumIds, songs: songIds)
            
            return true
        } catch {
            print("\(error)")
            return false
        }
    }
    
    private func allowDestructiveBehavior() -> Bool {
        return playRecords.count == 0 && player?.hasSomething != true
    }
    
    func parse(data: Data) {
        let rc = replaceData(data: data)
        if rc {
            buildMaps()
            save()
            notifyUpdate()
        }
    }
    
    func doFetch() {
        downloader.fetch(completion: parse)
    }
    
    func deleteImages() {
        if allowDestructiveBehavior() == false {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKeyCleanUpDone), object: self)
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: MusicLibrary.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
            
            for file in files {
                switch file.pathExtension {
                case "jpg":
                    try FileManager.default.removeItem(at: file)
                default:
                    break
                }
            }
        } catch {
            
        }

        downloadedImage = Set<Int>()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKeyDeleteImagesDone), object: self)
    }
    
    func getRandomSong() -> FullSong {
        let randomIndex = Int(arc4random_uniform(UInt32(songs.count)))
        let song = songs[randomIndex]
        return makeFullSong(song: song.info)
    }
    
    func makeFullSong(from song: NetworkSong) -> FullSong {
        var artistString = ""
        for artist in song.artists {
            artistString += (artistString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        
        var featureString = ""
        for artist in song.features {
            featureString += (featureString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        if featureString != "" {
            artistString += " feat. \(featureString)"
        }
        
        let plays = max(song.plays, playRecords[song.id]?.plays ?? 0)
        
        let fullSong = FullSong(id: song.id, title: normalizeString(string: song.title), artistString: normalizeString(string: artistString), albumId: song.albumId, plays: plays, minRank: song.minRank, track: nil, fromNetwork: true)
        
        return fullSong
    }
    
    private func parseNetworkSongs(data: Data) {
        do {
            let json = try decoder.decode([NetworkSong].self, from: data)
            var songs = [FullSong]()
            
            for song in json {
                if let song = songMap[song.id] {
                    songs.append(makeFullSong(song: song.info))
                } else {
                    songs.append(makeFullSong(from: song))
                }
            }
            
            var albumSet = Set<Int>()
            for song in songs {
                if downloadedImage.contains(song.albumId) == false {
                    albumSet.insert(song.albumId)
                }
            }
            
            for (_, id) in albumSet.enumerated() {
                if FileManager.default.fileExists(atPath: MusicLibrary.getImageLocalUrl(id).path) == false {
                    downloader.requestImage(id: id, callback: { (done: Bool) -> Void in
                        self.downloadedImage.insert(id)
                        
                        if done {
                            self.save()
                        }
                    })
                }
            }
            player?.addNetworkSongs(songs: songs)
        } catch {
            print("\(error)")
        }
    }
    
    func doNetworkShuffle() {
        downloader.shuffle(completion: parseNetworkSongs)
    }
    
    func parseThenPlayWebviewSongs(data: Data) {
        parseNetworkSongs(data: data)
    }
    
    func getChartSong(id: Int) -> [String: Any] {
        let fullSong = makeFullSong(song: songMap[id]!.info)
        var song = [String: Any]()
        
        song["id"] = fullSong.id
        song["title"] = fullSong.title
        song["artists"] = fullSong.artistString
        song["plays"] = fullSong.plays
        
        return song
    }
    
    func getWatchSongs() -> [[String: Any]] {
        var songIds = Set<Int>()
        
        if let albumPlaylist = playlists.first(where: { $0.name == "Current Albums" }) {
            getSongPlaylistFromAlbumPlaylist(albumPlaylist).list.forEach { id in songIds.insert(id) }
        }
        
        if let albumPlaylist = playlists.first(where: { $0.name == "Favorite Artists" }) {
            getSongPlaylistFromAlbumPlaylist(albumPlaylist).list.forEach { id in songIds.insert(id) }
        }
        
        var songs = [[String: Any]]()
        
        songIds.forEach { id in songs.append(getChartSong(id: id)) }
        
        print("\(songs.count)")
        
        return songs
    }
    
    func refreshAlbumImage(id: Int) {
        downloader.requestImage(id: id, callback: { (done: Bool) -> Void in
            self.downloadedImage.insert(id)
            
            if done {
                self.save()
            }
        })
    }
}
