//
//  AlbumCollectionViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class AlbumCollectionViewController: UICollectionViewController {
    
    var albums = [AlbumInfo]()
    var artist: ArtistInfo?
    var playlist: Playlist?
    var library: MusicLibrary?
    var showAllSongsCell = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView?.register(AlbumCollectionViewCell.nib, forCellWithReuseIdentifier: AlbumCollectionViewCell.identifier)
        self.collectionView?.register(AllSongsCollectionViewCell.nib, forCellWithReuseIdentifier: AllSongsCollectionViewCell.identifier)

        // Do any additional setup after loading the view.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        
        if let pl = playlist {
            self.title = pl.name
            self.albums = library!.getPlaylistAlbums(pl)
            if pl.name == "New Albums" {
                showAllSongsCell = true
            }
        } else if let a = artist {
            self.title = a.name
            self.albums = library!.getAlbumsByArtist(artist: a)
            albums.sort(by: { $0.release > $1.release })
            if albums.count > 1 {
                showAllSongsCell = true
            }
        } else {
            self.albums = library!.getAllAlbums()
            albums.sort(by: { $0.release > $1.release })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return albums.count + (showAllSongsCell ? 1 : 0)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == albums.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AllSongsCollectionViewCell.identifier, for: indexPath)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumCollectionViewCell.identifier, for: indexPath)
        
            // Configure the cell
            if let albumCell = cell as? AlbumCollectionViewCell {
                let album = albums[indexPath.row]
                albumCell.album = album
                albumCell.artists = library?.getAlbumArtistString(id: album.id)
            }
        
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == albums.count {
            performSegue(withIdentifier: "AlbumAllSongsSegue", sender: self)
        } else {
            performSegue(withIdentifier: "AlbumTrackSegue", sender: self)
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "AlbumTrackSegue":
                if let vc = segue.destination as? TrackTableViewController {
                    let album = albums[(collectionView?.indexPathsForSelectedItems![0].row)!]
                    vc.album = album
                    vc.artist = artist
                }
            case "AlbumAllSongsSegue":
                if let vc = segue.destination as? SongTableViewController {
                    if let pl = playlist {
                        vc.playlist = library?.getSongPlaylistFromAlbumPlaylist(pl)
                    } else if let artist = artist {
                        vc.playlist = library?.getAritstPlaylist(artist: artist)
                    }
                }
            default: break
            }
        }
    }

}
