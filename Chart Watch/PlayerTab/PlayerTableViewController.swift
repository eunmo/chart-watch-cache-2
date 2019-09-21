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
        
        self.tableView.register(PlayerNextUpTableViewCell.nib, forCellReuseIdentifier: PlayerNextUpTableViewCell.identifier)
        self.tableView.register(SongTableViewCell.nib, forCellReuseIdentifier: SongTableViewCell.identifier)
        self.tableView.register(PlayerShuffleTableViewCell.nib, forCellReuseIdentifier: PlayerShuffleTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerTableViewController.receiveNotification), name: NSNotification.Name(rawValue: MusicPlayer.updateNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerTableViewController.toggleEdit), name: NSNotification.Name(rawValue: PlayerNextUpTableViewCell.updateNotificationKey), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        player = appDelegate.player
        
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = CGFloat(20)
        
        pauseButton.isHidden = true
        progressView.progress = 0
        remainingTimeLabel.text = ""
        
        self.tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 59, bottom: 0, right: 0)
        
        CommonUI.makeSmallLayerCircular(layer: playCountLabel.layer)
        
        updateTopView()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
        
        if let player = player {
            if player.nextSongs.count > 0 {
                tableView.separatorStyle = .singleLine
            } else {
                tableView.separatorStyle = .none
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
    
    @objc func toggleEdit() {
        self.isEditing = !self.isEditing
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return player!.nextSongs.count > 0 ? 1 : 0
        case 1:
            return player!.nextSongs.count
        case 2:
            return player!.inShuffle ? 1 : 0
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: PlayerNextUpTableViewCell.identifier, for: indexPath)
            
            if let cell = cell as? PlayerNextUpTableViewCell {
                cell.count = player!.nextSongs.count
            }
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.identifier, for: indexPath)
            
            // Configure the cell...
            if let songCell = cell as? SongTableViewCell {
                songCell.song = player?.nextSongs[indexPath.row]
            }
            
            return cell
        case 2:
            return tableView.dequeueReusableCell(withIdentifier: PlayerShuffleTableViewCell.identifier, for: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        switch indexPath.section {
        case 0:
            let clearAction = UIAlertAction(title: "Clear", style: .destructive) { (action) in
                self.player?.clearNextSongs()
            }
            
            alert.addAction(clearAction)
            break
        case 1:
            let removeAction = UIAlertAction(title: "Remove From List", style: .destructive) { (action) in
                self.player?.removeSong(index: indexPath.row)
            }
            
            let lastSongAction = UIAlertAction(title: "Make This The Last Song", style: .default) { (action) in
                self.player?.makeLastSong(index: indexPath.row)
            }
            
            alert.addAction(removeAction)
            alert.addAction(lastSongAction)
            break
        case 2:
            let stopAction = UIAlertAction(title: "Stop Shuffle", style: .destructive) { (action) in
                self.player?.stopShuffle()
            }
        
            alert.addAction(stopAction)
            break
        default:
            break
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            tableView.deselectRow(at: indexPath, animated: false)
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == 1
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.player?.removeSong(index: indexPath.row)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        self.player?.moveSong(from: fromIndexPath.row, to: to.row)
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            var row = 0;
            
            if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
                row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1;
            }
            
            return IndexPath(row: row, section: sourceIndexPath.section);
        }
        
        return proposedDestinationIndexPath
    }

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
        if player?.currentSong == nil {
            return
        }
        
        let recordPlayAction = UIAlertAction(title: "Record Play", style: .destructive) { (action) in
            self.player?.skip(recordPlay: true)
        }
        
        let nextSongAction = UIAlertAction(title: "Next Song", style: .default) { (action) in
            self.player?.skip(recordPlay: false)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(recordPlayAction)
        alert.addAction(nextSongAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
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
