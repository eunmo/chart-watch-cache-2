//
//  MusicLibraryDataStructures.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/28/18.
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

struct AlbumInfo: Codable {
    let id: Int
    let tracks: [Track]
    let artists: [Int]
    var title: String
    let format: String?
    let format2: String?
    let release: Date
}

class Album: Codable {
    let info: AlbumInfo
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
    
    init(info: AlbumInfo) {
        self.info = info
    }
}

struct SongInfo: Codable {
    let id: Int
    var title: String
    let plays: Int
    let artists: [Int]
    let features: [Int]
}

class Song: Codable {
    var info: SongInfo
    var playCount: Int?
    var lastPlayed: Date?
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
    
    init(info: SongInfo) {
        self.info = info
    }
}

struct ServerJSON: Decodable {
    let singleCharts: [Int]
    let albumCharts: [Int]
    let charted: [Int]
    let uncharted: [Int]
    let favorites: [Int]
    let songs: [SongInfo]
    let albums: [AlbumInfo]
    let artists: [Artist]
}

struct FullSong {
    let id: Int
    let title: String
    let artistString: String
    let albumId: Int
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

struct PushData: Codable {
    let id: Int
    let plays: Int
    let lastPlayed: String
}

struct PullData: Codable {
    let id: Int
    let plays: Int    
}
