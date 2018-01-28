//
//  ArtistTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class ArtistTableViewController: UITableViewController {
    
    var initial: String = ""
    var artists = [ArtistInfo]()
    var library: MusicLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(ArtistTableViewCell.nib, forCellReuseIdentifier: ArtistTableViewCell.identifier)
        
        self.title = initial
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        artists = library!.getArtistsByInitial(initial: initial.first!)
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 59, 0, 0)
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
        return artists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArtistTableViewCell.identifier, for: indexPath)

        // Configure the cell...
        if let artistCell = cell as? ArtistTableViewCell {
            let artist = artists[indexPath.row]
            artistCell.name = artist.name
            artistCell.album = library!.getLatestAlbum(by: artist)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ArtistAlbumSegue", sender: self)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "ArtistAlbumSegue":
                if let vc = segue.destination as? AlbumCollectionViewController {
                    vc.artist = artists[tableView.indexPathForSelectedRow!.row]
                }
            default: break
            }
        }
    }

}
