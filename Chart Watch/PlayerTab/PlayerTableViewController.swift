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
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var remainingTimeLabel: UILabel! {
        didSet {
            remainingTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: remainingTimeLabel.font.pointSize, weight: UIFont.Weight.regular)
        }
    }
    @IBOutlet weak var playCountLabel: UILabel!
    
    var player: MusicPlayer?
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(SongTableViewCell.nib, forCellReuseIdentifier: SongTableViewCell.identifier)
        self.tableView.register(PlayerShuffleTableViewCell.nib, forCellReuseIdentifier: PlayerShuffleTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerTableViewController.receiveNotification), name: NSNotification.Name(rawValue: MusicPlayer.updateNotificationKey), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        player = appDelegate.player
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = CGFloat(20)
        
        pauseButton.isHidden = true
        progressView.progress = 0
        remainingTimeLabel.text = ""
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 59, 0, 0)
        
        CommonUI.makeSmallLayerCircular(layer: playCountLabel.layer)
        
        updateTopView()
    }
    
    func updateTopView() {
        if let currentSong = player?.currentSong {
            let imageUrl = MusicLibrary.getImageLocalUrl(currentSong.albumId)
            imageView.image = UIImage(contentsOfFile: imageUrl.path)
            titleLabel.text = currentSong.title
            artistLabel.text = currentSong.artistString
            progressView.isHidden = false
            remainingTimeLabel.isHidden = false
            playCountLabel.isHidden = false
            CommonUI.setPlayCountLabel(song: currentSong, label: playCountLabel)
        } else {
            imageView.image = nil
            titleLabel.text = "Chart Watch Cache"
            artistLabel.text = "Player"
            progressView.isHidden = true
            remainingTimeLabel.isHidden = true
            playCountLabel.isHidden = true
        }
        
        if let p = player, p.isPlaying == true {
            playButton.isHidden = true
            pauseButton.isHidden = false
            startTimer()
        } else {
            playButton.isHidden = false
            pauseButton.isHidden = true
            stopTimer()
        }
        
        if let count = player?.nextSongs.count {
            let noMoreSongs = (count == 0)
            nextUpLabel.isHidden = noMoreSongs
            separatorView.isHidden = noMoreSongs
            if count > 0 {
                nextUpLabel.text = "Next Up: \(count == 1 ? "" : "\(count) Songs")"
            }
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
        return player!.nextSongs.count + (player!.inShuffle  ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if player!.inShuffle && indexPath.row == player!.nextSongs.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: PlayerShuffleTableViewCell.identifier, for: indexPath)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier, for: indexPath)

            // Configure the cell...
            if let songCell = cell as? SongTableViewCell {
                songCell.song = player?.nextSongs[indexPath.row]
            }

            return cell
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func getRemainingTimeString(_ time: Double?) -> String {
        if let double = time {
            let time = Int(double)
            let minute = time / 60
            let second = time - 60 * minute
            return String(format: "–\u{2009}%02d:%02d", minute, second) // \u{2009} == 'thin space'
        } else {
            return ""
        }
    }
    
    @objc func updatePlayerProgress() {
        progressView.setProgress(player?.progress ?? 0, animated: false)
        remainingTimeLabel.text = getRemainingTimeString(player?.remainingTime)
    }
    
    func startTimer() {
        timer?.invalidate()
        updatePlayerProgress()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: (#selector(PlayerTableViewController.updatePlayerProgress)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        updatePlayerProgress()
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        player?.play()
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        player?.pause()
    }
    
    @IBAction func skipButtonPressed(_ sender: UIButton) {
        player?.skip()
    }
    
    @IBAction func shuffleButtonPressed(_ sender: UIButton) {
        if player?.currentSong == nil {
            player?.addSongsShuffle()
            return
        }
        
        let replaceLocalAction = UIAlertAction(title: "Replace", style: .destructive) { (action) in
            self.player?.replaceShuffle()
        }
        
        let addSongsCachedAction = UIAlertAction(title: "Add Cached Songs", style: .default) { (action) in
            self.player?.addSongsShuffle()
        }
        
        let addSongsStreamedAction = UIAlertAction(title: "Add Streamed Songs", style: .default) { (action) in
            self.player?.addSongsNetworkShuffle()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(replaceLocalAction)
        alert.addAction(addSongsCachedAction)
        alert.addAction(addSongsStreamedAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
}
