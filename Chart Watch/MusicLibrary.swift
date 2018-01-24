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

struct Album: Codable {
    let id: Int
    let tracks: [Track]
    let artists: [Int]
    var title: String
    let format: String?
    let format2: String?
    let release: Date
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
    let albums: [Album]
    let artists: [Artist]
}

struct FullSong {
    let id: Int
    let title: String
    let artists: [Artist]
    let features: [Artist]
    let artistString: String
    let album: Album?
    let track: Track?
    let order: Int?
}

class MusicLibray {
    
    // MARK: raw data array
    
    var songs = [Song]()
    var albums = [Album]()
    var artists = [Artist]()
    
    // MARK: indexed map
    
    var songMap = [Int: Song]()
    var albumMap = [Int: Album]()
    var artistMap = [Int: Artist]()    
    var initials = [Character: [Artist]]()
    
    let dateFormatter: DateFormatter = DateFormatter()
    let serverAddress = "http://192.168.219.137:3000"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        for char in Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            initials[char] = [Artist]()
        }
    }
    
    func normalizeString(string: String) -> String {
        return string.replacingOccurrences(of: "`", with: "'")
    }
    
    func testParse() {
        print("start parsing")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let urlAsString = "\(serverAddress)/ios/fetch2"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        print(url)
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if data != nil {
                do {
                    let json = try decoder.decode(ServerJSON.self, from: data!)
                    
                    for var song in json.songs {
                        song.title = self.normalizeString(string: song.title)
                        self.songs.append(song)
                        self.songMap[song.id] = song
                    }
                    
                    for var album in json.albums {
                        album.title = self.normalizeString(string: album.title)
                        self.albums.append(album)
                        self.albumMap[album.id] = album
                    }
                    
                    for var artist in json.artists {
                        artist.name = self.normalizeString(string: artist.name)
                        self.artists.append(artist)
                        self.artistMap[artist.id] = artist
                    }
                    
                    var initial: Character
                    for artist in self.artists {
                        initial = self.getInitial(name: artist.nameNorm)
                        self.initials[initial]?.append(artist)
                    }
                    
                    for (key, array) in self.initials {
                        self.initials[key] = array.sorted{ $0.nameNorm.lowercased() < $1.nameNorm.lowercased() }
                    }
                    
                    print("songs:\(self.songs.count) albums:\(self.albums.count) artists:\(self.artists.count)")
                } catch {
                    print("\(error)")
                }
            }
        })
        
        query.resume()
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
    
    func checkInitialExists(initial: Character) -> Bool {
        return initials[initial]!.count > 0
    }
    
    func getAlbumsByArtist(artist: Artist) -> [Album] {
        var albumIdSet = Set<Int>()
        
        for album in albums {
            if album.artists.contains(artist.id) {
                albumIdSet.insert(album.id)
            }
        }
        
        for song in songs {
            if song.artists.contains(artist.id) || song.features.contains(artist.id) {
                for album in albums {
                    for track in album.tracks {
                        if track.id == song.id {
                            albumIdSet.insert(album.id)
                        }
                    }
                }
            }
        }
        
        var artistAlbums = [Album]()
        
        for albumId in albumIdSet {
            artistAlbums.append(albumMap[albumId]!)
        }
        
        return artistAlbums
    }
    
    func makeFullSong(song: Song, track: Track? = nil) -> FullSong {
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
        
        let fullSong = FullSong(id: song.id, title: song.title, artists: songArtists, features: songFeatures, artistString: artistString, album: nil, track: track, order: nil)
        
        return fullSong
    }
    
    func getSongs() -> [FullSong] {
        var fullSongs = [FullSong]()
        
        for song in songs {
            fullSongs.append(makeFullSong(song: song))
        }
        
        return fullSongs
    }
    
    func getSongs(by album: Album) -> [FullSong] {
        var albumSongs = [FullSong]()
        
        for track in album.tracks {
            albumSongs.append(makeFullSong(song: songMap[track.id]!, track: track))
        }
        
        return albumSongs
    }
    
    func getSongs(by album: Album, filterBy artist: Artist) -> [FullSong] {
        
        if album.artists.contains(artist.id) {
            return getSongs(by: album)
        } else {
            var albumSongs = [FullSong]()
            
            for track in album.tracks {
                let song = songMap[track.id]!
                
                if song.artists.contains(artist.id) || song.features.contains(artist.id) {
                    albumSongs.append(makeFullSong(song: song, track: track))
                }
            }
            
            return albumSongs
        }
    }
}
