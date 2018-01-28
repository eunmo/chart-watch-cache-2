//
//  PlayerTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/27/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class PlayerTableViewController: UITableViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var nextUpLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    var library: MusicLibrary?
    var player: MusicPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(SongTableViewCell.nib, forCellReuseIdentifier: SongTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerTableViewController.receiveNotification), name: NSNotification.Name(rawValue: MusicPlayer.updateNotificationKey), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        player = appDelegate.player
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = CGFloat(20)
        
        pauseButton.isHidden = true
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 59, 0, 0)
        
        updateTopView()
    }
    
    func updateTopView() {
        if let currentSong = player?.currentSong {
            let imageUrl = MusicLibrary.getImageLocalUrl(currentSong.albumId)
            imageView.image = UIImage(contentsOfFile: imageUrl.path)
            titleLabel.text = currentSong.title
            artistLabel.text = currentSong.artistString
        }
        
        let noMoreSongs = (player!.nextSongs.count == 0)
        nextUpLabel.isHidden = noMoreSongs
        separatorView.isHidden = noMoreSongs
        if noMoreSongs == false {
            nextUpLabel.text = "Next Up: \(player!.nextSongs.count)"
        }
    }
    
    func update() {
        updateTopView()
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
        return player!.nextSongs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier, for: indexPath)

        // Configure the cell...
        if let songCell = cell as? SongTableViewCell {
            songCell.song = player?.nextSongs[indexPath.row]
        }

        return cell
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
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        playButton.isHidden = true
        pauseButton.isHidden = false
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        playButton.isHidden = false
        pauseButton.isHidden = true
    }
    
}
