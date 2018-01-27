//
//  TrackTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/27/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

struct Disk {
    let num: Int
    let songs: [FullSong]
}

class TrackTableViewController: UITableViewController {
    
    var artist: Artist?
    var album: AlbumS?
    var songs = [FullSong]()
    var disks = [Disk]()
    var library: MusicLibrary?
    var player: MusicPlayer?
    
    var min: Int?
    var max: Int?
    var diskCount: Int?
    
    @IBOutlet weak var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(TrackTableViewCell.nib, forCellReuseIdentifier: TrackTableViewCell.identifier)
        self.tableView.register(TrackTableViewHeaderView.nib, forHeaderFooterViewReuseIdentifier: TrackTableViewHeaderView.identifier)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        player = appDelegate.player
        
        if let album = self.album {
            if let artist = self.artist {
                songs = library!.getSongs(by: album, filterBy: artist)
            } else {
                songs = library!.getSongs(by: album)
            }
            navItem.largeTitleDisplayMode = .never
            self.title = ""
        }
        
        mapToDisks()
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 54, 0, 0)
    }
    
    func mapToDisks() {
        var diskMap = [Int: [FullSong]]()
        
        for song in songs {
            let disk = song.track!.disk
            if diskMap[disk] == nil {
                diskMap[disk] = [FullSong]()
            }
            diskMap[disk]?.append(song)
        }
        
        for (diskNum, songs) in diskMap {
            let disk = Disk(num: diskNum, songs: songs)
            disks.append(disk)
        }
        
        disks.sort(by: { $0.num < $1.num })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1 + disks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? 0 : disks[section - 1].songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TrackTableViewCell.identifier, for: indexPath)
        
        if let trackCell = cell as? TrackTableViewCell {
            trackCell.song = disks[indexPath.section - 1].songs[indexPath.row]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            if let album = self.album {
                if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TrackTableViewHeaderView.identifier) as? TrackTableViewHeaderView {
                    headerView.album = album
                    headerView.artists = library?.getAlbumArtistString(id: album.id)
                    return headerView
                }
            }
        } else {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat(165)
        } else if disks.last?.num == 1 {
            return CGFloat(0)
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "" : "DISK \(disks[section - 1].num)"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = disks[indexPath.section - 1].songs[indexPath.row]
        
        let playSongAction = UIAlertAction(title: "Play Now", style: .destructive) { (action) in
            self.player?.playNow(song)
            self.tabBarController?.selectedIndex = 1
        }
        
        let addSongsAction = UIAlertAction(title: "Add Songs", style: .default) { (action) in
            var newSongs = [FullSong]()
            
            for index in indexPath.row..<self.disks[indexPath.section - 1].songs.count {
                newSongs.append(self.disks[indexPath.section - 1].songs[index])
            }
            
            for section in (indexPath.section)..<self.disks.count {
                newSongs.append(contentsOf: self.disks[section].songs)
            }
            
            self.player?.addSongs(newSongs)
            self.tabBarController?.selectedIndex = 1
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("cancel!")
        }
        
        let alert = UIAlertController(title: song.title, message: "", preferredStyle: .actionSheet)
        alert.addAction(playSongAction)
        alert.addAction(addSongsAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
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
