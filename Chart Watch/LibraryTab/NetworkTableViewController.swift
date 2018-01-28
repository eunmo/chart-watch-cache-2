//
//  NetworkTableViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/28/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit

enum ManagementStatus {
    case ready
    case ongoing
    case done
}

class ManagementItem {
    let name: String
    var status: ManagementStatus = .ready
    let function: () -> Void
    
    init(name: String, function: @escaping () -> Void) {
        self.name = name
        self.function = function
    }
    
    func start() {
        status = .ongoing
        function()
    }
    
    func done() {
        status = .done
    }
}

class NetworkTableViewController: UITableViewController {
    
    var library: MusicLibrary?
    var items = [ManagementItem]()
    var doingAll = false
    var doAllIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.register(NetworkTableViewCell.nib, forCellReuseIdentifier: NetworkTableViewCell.identifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receivePushDone), name: NSNotification.Name(rawValue: Downloader.notificationKeyPushDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receivePullDone), name: NSNotification.Name(rawValue: Downloader.notificationKeyPullDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receiveFetchDone), name: NSNotification.Name(rawValue: Downloader.notificationKeyFetchDone), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetworkTableViewController.receiveCleanUpDone), name: NSNotification.Name(rawValue: MusicLibrary.notificationKeyCleanUpDone), object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        library = appDelegate.library
        
        items.append(ManagementItem(name: "Push", function: { self.library?.doPush() }))
        items.append(ManagementItem(name: "Pull", function: { self.library?.doPull() }))
        items.append(ManagementItem(name: "Fetch", function: { self.library?.doFetch() }))
        items.append(ManagementItem(name: "Clean Up", function: { self.library?.doCleanUp() }))
        items.append(ManagementItem(name: "Do All", function: { self.doAll() }))
        doAllIndex = items.count - 1
    }
    
    func update() {
        tableView.reloadData()
    }
    
    func optionDone(index: Int) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.items[index].done()
            if self.doingAll {
                self.doAll()
            }
            self.update()
        })
        
    }
    
    @objc func receivePushDone() {
        optionDone(index: 0)
    }
    
    @objc func receivePullDone() {
        optionDone(index: 1)
    }
    
    @objc func receiveFetchDone() {
        optionDone(index: 2)
    }
    
    @objc func receiveCleanUpDone() {
        optionDone(index: 3)
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
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetworkTableViewCell.identifier, for: indexPath)

        // Configure the cell...
        if let networkCell = cell as? NetworkTableViewCell {
            let item = items[indexPath.row]
            networkCell.item = item
            
            if indexPath.row == doAllIndex {
                cell.backgroundColor = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1)
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].start()
        update()
    }
    
    func doAll() {
        doingAll = true
        for item in items {
            if item.status == .ready {
                item.start()
                return
            }
        }
        doingAll = false
        optionDone(index: doAllIndex)
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
