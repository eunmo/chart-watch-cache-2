//
//  WebViewController.swift
//  Chart Watch
//
//  Created by Eunmo Yang on 1/30/18.
//  Copyright © 2018 Eunmo Yang. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var player: MusicPlayer?
    var blurView: UIVisualEffectView?
    
    override func loadView() {
        let userScript = WKUserScript(source: "setWebkit()", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.add(self, name: "addSongs")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        webView.scrollView.bounces = true
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshWebView(sender:)), for: UIControlEvents.valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let serverAddress = appDelegate.library.downloader.serverAddress
        webView.load(URLRequest(url: URL(string: serverAddress)!))
        
        player = appDelegate.player
    }
    override func viewWillAppear(_ animated: Bool) {
        if let statusbar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            blurView!.frame = statusbar.bounds
            statusbar.addSubview(blurView!)
            statusbar.sendSubview(toBack: blurView!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        blurView!.removeFromSuperview()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "addSongs" {
            if let body = message.body as? String, let data = body.removingPercentEncoding?.data(using: .utf8) {
                player?.addSongsFromWebView(data: data)
                self.tabBarController?.selectedIndex = 1
            }
        }
    }

    @objc func refreshWebView(sender: UIRefreshControl) {
        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let serverAddress = appDelegate.library.downloader.serverAddress
        webView.load(URLRequest(url: URL(string: serverAddress)!))
        sender.endRefreshing()
    }

}
