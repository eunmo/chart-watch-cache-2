//
//  SongTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/23/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class SongTableViewController: UITableViewController {
    
    var songs = [FullSong]()
    var playlist: Playlist?
    var library: MusicLibrary?
    var player: MusicPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(SongTableViewCell.nib, forCellReuseIdentifier: SongTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SongTableViewController.receiveNotification), name: NSNotification.Name(rawValue: MusicLibrary.notificationKey), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        player = appDelegate.player
        
        getSongs()
        
        if let pl = playlist {
            self.title = pl.name
        }
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 59, 0, 59)
    }
    
    func getSongs() {
        if let pl = playlist {
            songs = library!.getPlaylistSongs(pl)
        } else {
            songs = library!.getSongs().sorted(by: { $0.id > $1.id })
        }
    }
    
    func update() {
        getSongs()
        tableView.reloadData()
    }
    
    @objc func receiveNotification() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.update()
        })
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
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier, for: indexPath)

        // Configure the cell...
        if let songCell = cell as? SongTableViewCell {
            songCell.song = songs[indexPath.row]
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = songs[indexPath.row]
        
        let playSongAction = UIAlertAction(title: "Play Now", style: .destructive) { (action) in
            self.player?.playNow(song)
            self.tabBarController?.selectedIndex = 1
        }
        
        let addSongsAction = UIAlertAction(title: "Add Songs", style: .default) { (action) in
            var newSongs = [FullSong]()
            
            for index in indexPath.row..<self.songs.count {
                newSongs.append(self.songs[index])
            }
            
            self.player?.addSongs(newSongs)
            self.tabBarController?.selectedIndex = 1
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("cancel!")
        }
        
        let alert = UIAlertController(title: song.title, message: song.artistString, preferredStyle: .actionSheet)
        alert.addAction(playSongAction)
        if self.playlist?.name == "Current Singles" || self.playlist?.name == "Seasonal Songs" {
            alert.addAction(addSongsAction)
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }

    @IBAction func reverseOrderButtonPressed(_ sender: UIBarButtonItem) {
        songs.reverse()
        tableView.reloadData()        
    }
    
}
