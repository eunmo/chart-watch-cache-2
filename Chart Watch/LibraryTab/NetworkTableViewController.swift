//
//  NetworkTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/28/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit
import WatchConnectivity

enum ManagementStatus {
    case ready
    case ongoing
    case done
}

class ManagementItem {
    var name: String
    var status: ManagementStatus = .ready
    let function: () -> Void
    
    init(name: String, function: @escaping () -> Void) {
        self.name = name
        self.function = function
    }
    
    func start() {
        status = .ongoing
        function()
    }
    
    func done() {
        status = .done
    }
}

class NetworkTableViewController: UITableViewController {
    
    var library: MusicLibrary?
    var items = [ManagementItem]()
    var doingAll = false
    var doAllIndex = 0
    var sendFileIndex = 0
    
    var timer: Timer?
    var isSending = false
    var numSending = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(NetworkTableViewCell.nib, forCellReuseIdentifier: NetworkTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receivePushDone), name: NSNotification.Name(rawValue: Downloader.notificationKeySyncPlaysDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receiveFetchDone), name: NSNotification.Name(rawValue: Downloader.notificationKeyFetchDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receiveDeleteImagesDone), name: NSNotification.Name(rawValue: MusicLibrary.notificationKeyDeleteImagesDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receiveCheckDownloadsDone), name: NSNotification.Name(rawValue: MusicLibrary.notificationKeyCheckDownloadsDone), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        
        items.append(ManagementItem(name: "Sync Plays", function: { self.library?.doSync() }))
        items.append(ManagementItem(name: "Sync Plays on Watch", function: { self.syncWatch() }))
        items.append(ManagementItem(name: "Sync DB Cache", function: { self.library?.doFetch() }))
        items.append(ManagementItem(name: "Do All", function: { self.doAll() }))
        doAllIndex = items.count - 1
        items.append(ManagementItem(name: "", function: {}))
        items.append(ManagementItem(name: "Send Files to Watch", function: { self.sendFilesToWatch() }))
        sendFileIndex = items.count - 1
        items.append(ManagementItem(name: "", function: {}))
        items.append(ManagementItem(name: "Check Downloads", function: { self.library?.doCheckDownloads() }))
        items.append(ManagementItem(name: "Delete All Images", function: { self.library?.deleteImages() }))
        
        let session = WCSession.default
        let outstanding = session.outstandingFileTransfers.count
        if outstanding > 0 {
            numSending = outstanding
            items[sendFileIndex].status = .ongoing
            startTimer()
        }
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func optionDone(index: Int) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.items[index].done()
            if self.doingAll {
                self.doAll()
            }
            self.update()
        })
        
    }
    
    @objc func receivePushDone() {
        optionDone(index: 0)
    }
    
    func receiveWatchSyncDone(_ reply: [String: Any]) {
        optionDone(index: 1)
    }
    
    @objc func receiveFetchDone() {
        optionDone(index: 2)
    }
    
    @objc func receiveCheckDownloadsDone() {
        optionDone(index: 7)
    }
    
    @objc func receiveDeleteImagesDone() {
        optionDone(index: 8)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetworkTableViewCell.identifier, for: indexPath)

        // Configure the cell...
        if let networkCell = cell as? NetworkTableViewCell {
            let item = items[indexPath.row]
            networkCell.item = item
            
            if indexPath.row == doAllIndex {
                cell.backgroundColor = CommonUI.tealBlue
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].start()
        update()
    }
    
    func doAll() {
        doingAll = true
        for index in 0...doAllIndex {
            let item = items[index]
            if item.status == .ready {
                item.start()
                return
            }
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    func sendFilesToWatch() {
        var message = [String: Any]()
        message["request"] = "sync_songs"
        message["songs"] = library?.getWatchSongs() as Any
        
        let session = WCSession.default
        session.sendMessage(message, replyHandler: sendFiles)
    }
    
    func sendFiles(_ reply: [String: Any]) {
        let session = WCSession.default
        
        if let value = reply["ids"], let array = value as? [Int] {
            isSending = true
            for songId in array {
                let url = MusicLibrary.getMediaLocalUrl(songId)
                session.transferFile(url, metadata: ["id": songId])
                print("\(songId) sent")
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.numSending = array.count
                self.startTimer()
            })
        }
    }
    
    @objc func updateSendFileStatus() {
        let session = WCSession.default
        let outstanding = session.outstandingFileTransfers
        
        items[sendFileIndex].name = "Send Files to Watch ... \(numSending - outstanding.count)/\(numSending)"
        update()
        if outstanding.count == 0 {
            numSending = 0
            stopTimer()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        updateSendFileStatus()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: (#selector(NetworkTableViewController.updateSendFileStatus)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        items[sendFileIndex].name = "Send Files to Watch ... Done"
        items[sendFileIndex].status = .done
        timer?.invalidate()
        timer = nil
    }
    
    func syncWatch() {
        var message = [String: Any]()
        message["request"] = "sync_plays"
        
        let session = WCSession.default
        session.sendMessage(message, replyHandler: receiveWatchSyncDone)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
