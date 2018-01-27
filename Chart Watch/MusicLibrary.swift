//
//  MusicLibrary.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/21/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation

struct Artist: Codable {
    let id: Int
    var name: String
    let nameNorm: String
}

struct Track: Codable {
    let id: Int
    let disk: Int
    let track: Int
}

struct AlbumS: Codable {
    let id: Int
    let tracks: [Track]
    let artists: [Int]
    var title: String
    let format: String?
    let format2: String?
    let release: Date
}

class Album: Codable {
    let info: AlbumS
    var downloaded = false
    
    var id: Int {
        get {
            return info.id
        }
    }
    
    var title: String {
        get {
            return info.title
        }
    }
    
    init(info: AlbumS) {
        self.info = info
    }
}

struct Song: Codable {
    let id: Int
    var title: String
    let plays: Int
    let lastPlayed: Date?
    let artists: [Int]
    let features: [Int]
}

struct ServerJSON: Decodable {
    let singleCharts: [Int]
    let albumCharts: [Int]
    let charted: [Int]
    let uncharted: [Int]
    let favorites: [Int]
    let songs: [Song]
    let albums: [AlbumS]
    let artists: [Artist]
}

struct FullSong {
    let id: Int
    let title: String
    let artists: [Artist]
    let features: [Artist]
    let artistString: String
    let album: AlbumS?
    let track: Track?
}

struct Archive: Codable {
    let songs: [Song]
    let albums: [Album]
    let artists: [Artist]
    let playlists: [Playlist]
}

enum PlaylistType: Int, Codable {
    case albumPlaylist
    case songPlaylist
}

struct Playlist: Codable {
    let playlistType: PlaylistType
    let name: String
    let list: [Int]
}

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
    
    let dateFormatter: DateFormatter = DateFormatter()
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("library")
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        for char in Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            initials[char] = [Artist]()
        }
    }
    
    func save() {
        let archive = Archive(songs: songs, albums: albums, artists: artists, playlists: playlists)
        let data = try! PropertyListEncoder().encode(archive)
        NSKeyedArchiver.archiveRootObject(data, toFile: MusicLibrary.ArchiveURL.path)
    }
    
    func load() {
        if let data = NSKeyedUnarchiver.unarchiveObject(withFile: MusicLibrary.ArchiveURL.path) as? Data {
            let archive = try! PropertyListDecoder().decode(Archive.self, from: data)
            self.songs = archive.songs
            self.albums = archive.albums
            self.artists = archive.artists
            self.playlists = archive.playlists
            buildMaps()
            startDownload()
        } else {
            downloader.fetch(completion: parse)
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
    
    func normalizeString(string: String) -> String {
        return string.replacingOccurrences(of: "`", with: "'")
    }
    
    func parse(data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let json = try decoder.decode(ServerJSON.self, from: data)
            
            for var song in json.songs {
                song.title = self.normalizeString(string: song.title)
                songs.append(song)
            }
            
            for var albumS in json.albums {
                albumS.title = self.normalizeString(string: albumS.title)
                let album = Album(info: albumS)
                albums.append(album)
            }
            
            for var artist in json.artists {
                artist.name = self.normalizeString(string: artist.name)
                artists.append(artist)
            }
            
            playlists.append(Playlist(playlistType: .songPlaylist, name: "Current Singles", list: json.singleCharts))
            playlists.append(Playlist(playlistType: .albumPlaylist, name: "Current Albums", list: json.albumCharts))
            playlists.append(Playlist(playlistType: .songPlaylist, name: "Charted Songs", list: json.charted))
            playlists.append(Playlist(playlistType: .songPlaylist, name: "Uncharted Songs", list: json.uncharted))
            playlists.append(Playlist(playlistType: .albumPlaylist, name: "Favorite Artists", list: json.favorites))
            
            buildMaps()
            
            save()
            
            startDownload()
        } catch {
            print("\(error)")
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
    
    func albumDownloadDone() -> Bool {
        for album in albums {
            if album.downloaded == false {
                return false
            }
        }
        
        return true
    }
    
    func startDownload() {
        for album in albums {
            if album.downloaded != true {
                downloader.requestImage(id: album.id, callback: {
                    album.downloaded = true
                    if self.albumDownloadDone() {
                        print("all albums downloaded")
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
    
    func getArtistsByInitial(initial: Character) -> [Artist] {
        return initials[initial]!
    }
    
    func getInitialCount(initial: Character) -> Int {
        return initials[initial]!.count
    }
    
    func getAllAlbums() -> [AlbumS] {
        var albums = [AlbumS]()
        
        for album in self.albums {
            albums.append(album.info)
        }
        
        return albums
    }
    
    func getLatestAlbum(by artist: Artist) -> AlbumS? {
        let albumIds = artistAlbums[artist.id]!
        var albums = [AlbumS]()
        
        for albumId in albumIds {
            albums.append(albumMap[albumId]!.info)
        }
        
        if (albums.count > 0) {
            albums.sort(by: { $0.release > $1.release })
            return albums[0]
        }
        
        return nil
    }
    
    func getAlbumsByArtist(artist: Artist) -> [AlbumS] {
        var albumIdSet = Set<Int>()
        
        for album in albums {
            if album.info.artists.contains(artist.id) {
                albumIdSet.insert(album.id)
            }
        }
        
        for song in songs {
            if song.artists.contains(artist.id) || song.features.contains(artist.id) {
                for album in albums {
                    for track in album.info.tracks {
                        if track.id == song.id {
                            albumIdSet.insert(album.id)
                        }
                    }
                }
            }
        }
        
        var artistAlbums = [AlbumS]()
        
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
    
    func makeFullSong(song: Song, track: Track? = nil, album: AlbumS? = nil) -> FullSong {
        var songArtists = [Artist]()
        var songFeatures = [Artist]()
        var artist: Artist
        
        var artistString = ""
        for artistId in song.artists {
            artist = artistMap[artistId]!
            songArtists.append(artist)
            artistString += (artistString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        
        var featureString = ""
        for artistId in song.features {
            artist = artistMap[artistId]!
            songFeatures.append(artist)
            featureString += (featureString == "") ? "\(artist.name)" : ", \(artist.name)"
        }
        if featureString != "" {
            artistString += " feat. \(featureString)"
        }
        
        let songAlbum = album != nil ? album : albumMap[songAlbums[song.id]![0]]!.info
        
        let fullSong = FullSong(id: song.id, title: song.title, artists: songArtists, features: songFeatures, artistString: artistString, album: songAlbum, track: track)
        
        return fullSong
    }
    
    func getSongs() -> [FullSong] {
        var fullSongs = [FullSong]()
        
        for song in songs {
            fullSongs.append(makeFullSong(song: song))
        }
        
        return fullSongs
    }
    
    func sortByTracks(songA: FullSong, songB: FullSong) -> Bool {
        let a = songA.track!
        let b = songB.track!
        
        return a.disk != b.disk ? a.disk < b.disk : a.track < b.track
    }
    
    func getSongs(by album: AlbumS) -> [FullSong] {
        var albumSongs = [FullSong]()
        
        for track in album.tracks {
            albumSongs.append(makeFullSong(song: songMap[track.id]!, track: track, album: album))
        }
        
        albumSongs.sort(by: sortByTracks)
        
        return albumSongs
    }
    
    func getSongs(by album: AlbumS, filterBy artist: Artist) -> [FullSong] {
        
        if album.artists.contains(artist.id) {
            return getSongs(by: album)
        } else {
            var albumSongs = [FullSong]()
            
            for track in album.tracks {
                let song = songMap[track.id]!
                
                if song.artists.contains(artist.id) || song.features.contains(artist.id) {
                    albumSongs.append(makeFullSong(song: song, track: track, album: album))
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
    
    func getPlaylistAlbums(_ playlist: Playlist) -> [AlbumS] {
        if playlist.playlistType != .albumPlaylist {
            return [AlbumS]()
        }
        
        var albums = [AlbumS]()
        
        for albumId in playlist.list {
            albums.append(albumMap[albumId]!.info)
        }
        
        return albums
    }
    
    func getPlaylistSongs(_ playlist: Playlist) -> [FullSong] {
        var playlistSongs = [FullSong]()
        
        for songId in playlist.list {
            playlistSongs.append(makeFullSong(song: songMap[songId]!))
        }
        
        return playlistSongs
    }
}
