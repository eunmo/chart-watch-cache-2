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
        
        if previousVC == viewController, let vc = viewController as? WebViewController {
            vc.reload()
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
