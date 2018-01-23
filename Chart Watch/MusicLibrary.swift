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
    let name: String
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
    let title: String
    let format: String?
    let format2: String?
    let release: Date
}

struct Song: Codable {
    let id: Int
    let title: String
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

class MusicLibray {
    
    var songs = [Song]()
    var albums = [Album]()
    var artists = [Artist]()
    
    var initials = [Character: [Artist]]()
    
    let dateFormatter: DateFormatter = DateFormatter()
    let serverAddress = "http://192.168.219.137:3000"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        for char in Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ#ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
            initials[char] = [Artist]()
        }
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
                    self.songs = json.songs
                    self.albums = json.albums
                    self.artists = json.artists
                    
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
        
        for album in albums {
            if albumIdSet.contains(album.id) {
                artistAlbums.append(album)
            }
        }
        
        return artistAlbums
    }
}
