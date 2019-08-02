//
//  InterfaceController.swift
//  WatchKit Extension
//
//  Created by Eunmo Yang on 2019/08/03.
//  Copyright © 2019 Eunmo Yang. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {
    @IBOutlet weak var syncButton: WKInterfaceButton!
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var shuffleButton: WKInterfaceButton!
    @IBOutlet weak var label2: WKInterfaceLabel!
    
    var songlist: WatchSongs?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        songlist = watchDelegate.songlist
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateUI()
    }
    
    func updateUI() {
        label.setText("\(songlist!.songs.count) songs!")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func handleReply(reply: [String: Any]) {
        songlist!.parseSongList(reply)
        label.setText("\(songlist!.songs.count) songs")
    }

    @IBAction func onSync() {
        let session = WCSession.default
        session.sendMessage(["request": "list_songs"], replyHandler: handleReply)
    }
    
    @IBAction func onShuffle() {
        let randomIndex = Int(arc4random_uniform(UInt32(songlist!.songs.count)))
        label2.setText(songlist!.songs[randomIndex].title)
    }
}
