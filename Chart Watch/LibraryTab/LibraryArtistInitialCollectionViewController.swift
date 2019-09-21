//
//  LibraryArtistCollectionViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/22/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

class LibraryArtistInitialCollectionViewController: UICollectionViewController {
    
    let initialOrder = Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎABCDEFGHIJKLMNOPQRSTUVWXYZ#")
    var initials = [Character]()
    var counts = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView?.register(LibraryArtistInitialCollectionViewCell.nib, forCellWithReuseIdentifier: LibraryArtistInitialCollectionViewCell.identifier)

        // Do any additional setup after loading the view.
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let library = appDelegate.library
        
        for char in initialOrder {
            let count = library.getInitialCount(initial: char)
            if count > 0 {
                initials.append(char)
                counts.append(count)
            }
        }
        
        self.collectionView.backgroundColor = UIColor.systemBackground
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
        return initials.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryArtistInitialCollectionViewCell.identifier, for: indexPath)
        
        if let initialCell = cell as? LibraryArtistInitialCollectionViewCell {
            initialCell.initial = initials[indexPath.row]
            initialCell.count = counts[indexPath.row]
        }
    
        // Configure the cell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "LibraryArtistInitialSegue", sender: self)
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
            case "LibraryArtistInitialSegue":
                if let vc = segue.destination as? ArtistTableViewController {
                    vc.initial = "\(initials[(collectionView?.indexPathsForSelectedItems![0].row)!])"
                }
            default: break
            }
        }
    }
}
