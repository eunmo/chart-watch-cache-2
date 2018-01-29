//
//  MusicLibrary.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/21/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation

class MusicLibrary {
    
    // MARK: raw data array
    
    var songs = [Song]()
    var albums = [Album]()
    var artists = [Artist]()
    var playlists = [Playlist]()
    
    // MARK: indexed map
    
    var songMap = [Int: Song]()
    var albumMap = [Int: Album]()
    var artistMap = [Int: Artist]()
    var artistAlbums = [Int: [Int]]()
    var songAlbums = [Int: [Int]]()
    var initials = [Character: [Artist]]()
    
    let downloader = Downloader()
    var player: MusicPlayer?
    
    let dateFormatter: DateFormatter = DateFormatter()
    let decoder: JSONDecoder
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("library")
    static let notificationKey = "MusicPlayerNotificationKey"
    static let notificationKeyCleanUpDone = "MusicPlayerNotificationKey - CleanUp"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        for char in Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            initials[char] = [Artist]()
        }
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func save() {
        let archive = Archive(songs: songs, albums: albums, artists: artists, playlists: playlists)
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
                buildMaps()
                startDownload()
                return
            }
        }
    }
    
    func buildMaps() {
        for song in songs {
            songMap[song.id] = song
            songAlbums[song.id] = [Int]()
        }
        
        for album in albums {
            albumMap[album.info.id] = album
        }
        
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
    
    func downloadDone() -> Bool {
        for album in albums {
            if album.downloaded == false {
                return false
            }
        }
        
        for song in songs {
            if song.downloaded == false {
                return false
            }
        }
        
        return true
    }
    
    func startDownload() {
        for album in albums {
            if album.downloaded != true {
                if FileManager.default.fileExists(atPath: MusicLibrary.getImageLocalUrl(album.id).path) {
                    album.downloaded = true
                    continue
                }
                
                downloader.requestImage(id: album.id, callback: {
                    album.downloaded = true
                    if self.downloadDone() {
                        self.save()
                    }
                })
            }
        }
        
        for song in songs {
            if song.downloaded != true {
                if FileManager.default.fileExists(atPath: MusicLibrary.getMediaLocalUrl(song.id).path) {
                    song.downloaded = true
                    continue
                }
                
                downloader.requestMedia(id: song.id, callback: {
                    song.downloaded = true
                    if self.downloadDone() {
                        self.save()
                    }
                })
            }
        }
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
    
    func getPlaylistAlbumIds(_ playlist: Playlist) -> [Int] {
        if playlist.playlistType == .albumPlaylist {
            return playlist.list
        }
        
        var albums = [Int]()
        
        for songId in playlist.list {
            let albumId = songAlbums[songId]![0]
            if albums.last != albumId {
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
            playlistSongs.append(makeFullSong(song: songMap[songId]!.info))
        }
        
        return playlistSongs
    }
    
    func getLocallyPlayedPlaylist() -> Playlist {
        var locallyPlayed = [Song]()
        
        for song in songs {
            if song.lastPlayed != nil {
                locallyPlayed.append(song)
            }
        }
        
        locallyPlayed.sort(by: { $0.lastPlayed! < $1.lastPlayed! })
        
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
    
    func recordPlay(_ fullSong: FullSong) {
        let song = songMap[fullSong.id]!
        
        if song.playCount == nil {
            song.playCount = song.info.plays + 1
        } else {
            song.playCount! += 1
        }
        
        song.lastPlayed = Date()
        updatePlay(song: song, playCount: song.playCount!)
        save()
        notifyUpdate()
    }
    
    func getPushData() -> [PushData] {
        var data = [PushData]()
        
        for song in songs {
            if song.playCount != nil {
                data.append(PushData(id: song.id, plays: song.playCount!, lastPlayed: dateFormatter.string(from: song.lastPlayed!)))
            }
        }
        
        return data
    }
    
    func doPush() {
        downloader.push(pushData: getPushData())
    }
    
    func getPullData() -> [Int] {
        return songs.map({ $0.id })
    }
    
    func notifyUpdate() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKey), object: self)
    }
    
    func updatePlay(song: Song, playCount: Int) {
        let info = song.info
        let newInfo = SongInfo(id: info.id, title: info.title, plays: playCount, minRank: info.minRank, artists: info.artists, features: info.features)
        song.info = newInfo
    }
    
    func updatePlays(data: Data) {
        do {
            let json = try decoder.decode([PullData].self, from: data)
            
            for data in json {
                if let song = songMap[data.id] {
                    if let plays = song.playCount {
                        if plays <= data.plays {
                            song.playCount = nil
                            song.lastPlayed = nil
                        }
                    }
                    
                    if song.info.plays != data.plays {
                        updatePlay(song: song, playCount: data.plays)
                    }
                }
            }
            
            save()
            notifyUpdate()
        } catch {
            print("\(error)")
        }
    }
    
    func doPull() {
        downloader.pull(pullData: getPullData(), completion: updatePlays)
    }
    
    func normalizeString(string: String) -> String {
        return string.replacingOccurrences(of: "`", with: "'")
    }
    
    func addPlaylists(json: ServerJSON) {
        playlists = [Playlist]()
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Current Singles", list: json.singleCharts))
        playlists.append(Playlist(playlistType: .albumPlaylist, name: "Current Albums", list: json.albumCharts))
        playlists.append(Playlist(playlistType: .albumPlaylist, name: "Favorite Artists", list: json.favorites))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Seasonal Songs", list: json.seasonal))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Charted Songs", list: json.charted))
        playlists.append(Playlist(playlistType: .songPlaylist, name: "Unfamiliar Songs", list: json.uncharted))
    }
    
    func replaceData(data: Data) -> Bool {
        do {
            let json = try decoder.decode(ServerJSON.self, from: data)
            
            songs = [Song]()
            for var songInfo in json.songs {
                songInfo.title = self.normalizeString(string: songInfo.title)
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
            
            return true
        } catch {
            print("\(error)")
            return false
        }
    }
    
    func updateData(data: Data) -> Bool {
        do {
            let json = try decoder.decode(ServerJSON.self, from: data)
            
            for var songInfo in json.songs {
                songInfo.title = self.normalizeString(string: songInfo.title)
                if let song = songMap[songInfo.id] {
                    song.info = songInfo
                    
                    if let plays = song.playCount {
                        if plays <= song.info.plays {
                            song.playCount = nil
                            song.lastPlayed = nil
                        } else {
                            updatePlay(song: song, playCount: plays)
                        }
                    }
                } else {
                    songs.append(Song(info: songInfo))
                }
            }
            
            for var albumInfo in json.albums {
                albumInfo.title = self.normalizeString(string: albumInfo.title)
                if let album = albumMap[albumInfo.id] {
                    album.info = albumInfo
                } else {
                    albums.append(Album(info: albumInfo))
                }
            }
            
            for var artistInfo in json.artists {
                artistInfo.name = self.normalizeString(string: artistInfo.name)
                if let artist = artistMap[artistInfo.id] {
                    artist.info = artistInfo
                } else {
                    artists.append(Artist(info: artistInfo))
                }
            }
            
            addPlaylists(json: json)
            
            return true
        } catch {
            print("\(error)")
            return false
        }
    }
    
    func parse(data: Data) {
        let locallyPlayed = getLocallyPlayedPlaylist()
        var rc = false
        
        if locallyPlayed.list.count > 0 || player?.hasSomething == true {
            rc = updateData(data: data)
        } else {
            rc = replaceData(data: data)
        }
        
        if rc {
            buildMaps()
            save()
            notifyUpdate()
            startDownload()
        }
    }
    
    
    func doFetch() {
        downloader.fetch(completion: parse)
    }
    
    func doCleanUp() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: MusicLibrary.DocumentsDirectory, includingPropertiesForKeys: [], options: [])
            var imageCount = 0
            var mediaCount = 0
            
            for file in files {
                switch file.pathExtension {
                case "mp3":
                    if let song = Int((file.deletingPathExtension().lastPathComponent)) , songMap[song] == nil {
                        try FileManager.default.removeItem(at: file)
                        mediaCount += 1
                    }
                case "jpg":
                    if let album = Int((file.deletingPathExtension().lastPathComponent)) , albumMap[album] == nil {
                        try FileManager.default.removeItem(at: file)
                        imageCount += 1
                    }
                default:
                    break
                }
            }
        } catch {
            
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MusicLibrary.notificationKeyCleanUpDone), object: self)
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
        
        let fullSong = FullSong(id: song.id, title: song.title, artistString: artistString, albumId: song.albumId, plays: song.plays, minRank: song.minRank, track: nil, fromNetwork: true)
        
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
                if albumMap[song.albumId] == nil {
                    albumSet.insert(song.albumId)
                }
            }
            
            let missingAlbumIds = Array(albumSet)
            for id in missingAlbumIds {
                downloader.requestImage(id: id, callback: {})
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
}
