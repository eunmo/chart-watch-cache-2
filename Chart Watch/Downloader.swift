//
//  Downloader.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/25/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import Foundation

enum DownloadStatus {
    case ready
    case ongoing
    case done
    case failed
}

enum DownloadType {
    case image
    case media
}

class Downloader {
    
    var requests = [DownloadRequest]()
    var processCount = 0
    
    let serverAddress = "http://192.168.219.137:3000"
    let simultaneousDownloadLimit = 8
    
    static let notificationKey = "DownloaderNotificationKey"
    static let notificationKeyPushDone = "DownloaderNotificationKey - Push"
    
    class DownloadRequest {
        let id: Int
        var type: DownloadType
        var status: DownloadStatus = .ready
        let callback: () -> Void
        let localUrl: URL
        let serverUrl: URL
        
        init(id: Int, type: DownloadType, callback: @escaping () -> Void, localUrl: URL, serverUrl: URL) {
            self.id = id
            self.type = type
            self.callback = callback
            self.localUrl = localUrl
            self.serverUrl = serverUrl
        }
    }
    
    func push(pushData: [PushData]) {
        if let data = try? JSONEncoder().encode(pushData) {
            
            let urlAsString = "\(serverAddress)/ios/plays/push"
            let url = URL(string: urlAsString)!
            let urlSession = URLSession.shared
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = urlSession.dataTask(with: request, completionHandler: { data, response, error -> Void in
                self.notify(type: Downloader.notificationKeyPushDone)
            })
            task.resume()
        }
    }
    
    func fetch(completion: @escaping (Data) -> Void) {
        let urlAsString = "\(serverAddress)/ios/fetch2"
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if let d = data {
                completion(d)
            }
            
        })
        
        query.resume()
    }
    
    private func getNextRequest() -> DownloadRequest? {
        for request in requests{
            if request.status == .ready {
                return request
            }
        }
        
        return nil
    }
    
    private func saveFile(data: Data, url: URL) -> Bool {
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            return false
        }
        
        return true
    }
    
    private func downloadThenSave(request: DownloadRequest, callback: @escaping (Bool) -> Void) {
        let url = request.serverUrl
        let urlSession = URLSession.shared
        
        let query = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet {
                callback(false)
                return
            }
            
            if let d = data {
                if self.saveFile(data: d, url: request.localUrl) == false {
                    callback(false)
                } else {
                    callback(true)
                }
            } else {
                self.downloadThenSave(request: request, callback: callback)
            }
        })
        
        query.resume()
    }
    
    private func resume() {
        while true {
            if let request = getNextRequest() {
                if processCount == simultaneousDownloadLimit {
                    return
                }
                
                processCount += 1
                request.status = .ongoing
                downloadThenSave(request: request, callback: { success in
                    if success {
                        request.status = .done
                        request.callback()
                        self.notify(type: Downloader.notificationKey)
                    } else {
                        request.status = .failed
                    }
                    
                    self.processCount -= 1
                    self.resume()
                })
            } else {
                return
            }
        }
    }
    
    func requestImage(id: Int, callback: @escaping () -> Void) {
        let localUrl = MusicLibrary.getImageLocalUrl(id)
        let serverUrl = URL(string: "\(serverAddress)/\(id).jpg")!
        let request = DownloadRequest(id: id, type: .image, callback: callback, localUrl: localUrl, serverUrl: serverUrl)
        requests.append(request)
        resume()
    }
    
    func requestMedia(id: Int, callback: @escaping () -> Void) {
        let localUrl = MusicLibrary.getMediaLocalUrl(id)
        let serverUrl = URL(string: "\(serverAddress)/music/\(id).mp3")!
        let request = DownloadRequest(id: id, type: .image, callback: callback, localUrl: localUrl, serverUrl: serverUrl)
        requests.append(request)
        resume()
    }
    
    func getStatus() -> (Int, Int) {
        var doneCount = 0;
        
        for request in requests {
            if request.status == .done {
                doneCount += 1
            }
        }
        
        return (doneCount, requests.count)
    }
    
    func notify(type: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: type), object: self)
    }
}
