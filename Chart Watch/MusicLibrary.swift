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
    
    let dateFormatter: DateFormatter = DateFormatter()
    let serverAddress = "http://192.168.219.137:3000"
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
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
                    print("songs:\(self.songs.count) albums:\(self.albums.count) artists:\(self.artists.count)")
                } catch {
                    print("\(error)")
                }
            }
        })
        
        query.resume()
    }
}
