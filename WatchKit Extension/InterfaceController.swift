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
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var shuffleButton: WKInterfaceButton!
    @IBOutlet weak var label2: WKInterfaceLabel!
    
    var songlist: WatchSongs?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.receiveNotification), name: NSNotification.Name(rawValue: WatchSongs.notificationKey), object: nil)
        
        let watchDelegate = WKExtension.shared().delegate as! ExtensionDelegate
        songlist = watchDelegate.songlist
    }
    
    func updateUI() {
        let (songCount, savedSongs, extra) = songlist!.getStatus()
        label.setText("\(savedSongs)/\(songCount) songs!")
    }
    
    @objc func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.updateUI()
        })
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateUI()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func onShuffle() {
        if let randomSong = songlist!.getRandomSavedSong() {
            label2.setText(randomSong.title)
        }
    }
}
