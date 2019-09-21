//
//  TabBarController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 3/31/19.
//  Copyright © 2019 Eunmo Yang. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var previousVC = UIViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // Do any additional setup after loading the view.
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("??? \(tabBarController.selectedIndex)")
        
        if previousVC == viewController && tabBarController.selectedIndex == 2 {
            print("!!!")
            NotificationCenter.default.post(name: Notification.Name(rawValue: WebViewController.updateNotificationKey), object: self)
            //vc.reload()
        }
        
        previousVC = viewController
        
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
