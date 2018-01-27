//
//  LibraryTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/21/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class LibraryTableViewController: UITableViewController {
    
    let section1 = ["Artists", "Albums", "Songs", ""]
    var playlists = [Playlist]()
    var library: MusicLibrary?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(LibraryBasicTableViewCell.nib, forCellReuseIdentifier: LibraryBasicTableViewCell.identifier)
        self.tableView.register(LibraryPlaylistTableViewCell.nib, forCellReuseIdentifier: LibraryPlaylistTableViewCell.identifier)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 66.0
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        playlists = library!.playlists
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? section1.count : playlists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: LibraryBasicTableViewCell.identifier, for: indexPath) as? LibraryBasicTableViewCell {
                cell.title = "\(section1[indexPath.row])"
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: LibraryPlaylistTableViewCell.identifier, for: indexPath) as? LibraryPlaylistTableViewCell {
                let playlist = playlists[indexPath.row]
                cell.title = playlist.name
                cell.albumIds = library?.getPlaylistAlbumIds(playlist)
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "LibraryArtistSegue", sender: self)
                break
            case 1:
                performSegue(withIdentifier: "LibraryAlbumSegue", sender: self)
                break
            case 2:
                performSegue(withIdentifier: "LibrarySongSegue", sender: self)
                break
            default:
                break
            }
        } else if indexPath.section == 1 {
            let playlist = playlists[indexPath.row]
            
            switch playlist.playlistType {
            case .albumPlaylist:
                performSegue(withIdentifier: "LibraryAlbumSegue", sender: self)
                break
            case .songPlaylist:
                performSegue(withIdentifier: "LibrarySongSegue", sender: self)
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            return 78.0
        default:
            return 44.0
        }
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier, let indexPath = tableView.indexPathForSelectedRow, indexPath.section == 1 {
            switch identifier {
            case "LibraryAlbumSegue":
                if let vc = segue.destination as? AlbumCollectionViewController {
                    vc.playlist = playlists[indexPath.row]
                }
            case "LibrarySongSegue":
                if let vc = segue.destination as? SongTableViewController {
                    vc.playlist = playlists[indexPath.row]
                }
            default:
                break
            }
        }
    }
}
