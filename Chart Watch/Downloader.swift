//
//  Downloader.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/25/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation

struct ImageRequest {
    let id: Int
}
struct MediaRequest {
    let id: Int
}

class Downloader {
    
    let serverAddress = "http://192.168.219.137:3000"
    
    func fetch(completion: @escaping (Data) -> Void) {
        let urlAsString = "\(serverAddress)/ios/fetch2"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        print("download Start")
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if let d = data {
                print("download Done")
                completion(d)
            }
            
        })
        
        query.resume()
    }
}
