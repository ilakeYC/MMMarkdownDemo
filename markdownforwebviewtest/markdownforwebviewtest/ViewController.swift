//
//  ViewController.swift
//  markdownforwebviewtest
//
//  Created by LakesMac on 2016/10/20.
//  Copyright © 2016年 Dabllo. All rights reserved.
//

import UIKit
import MMMarkdown

class ViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("load \(request)")
        print(webView.scrollView.contentSize)
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("finish")
        print(webView.scrollView.contentSize)
    }
    
    


    @IBAction func leftBarButtonAction(sender: UIBarButtonItem) {
        guard let path = NSBundle.mainBundle().pathForResource("article", ofType: "txt") else {
            print("没有路径")
            return
        }
        print(path)
        
        guard let markdownText = try? String(contentsOfURL: NSURL(fileURLWithPath: path), encoding: NSUTF8StringEncoding) else {
            print("没有内容")
            return
        }
        
        guard let html = try? MMMarkdown.HTMLStringWithMarkdown(markdownText, extensions: MMMarkdownExtensions.GitHubFlavored) else {
            print("无法载入")
            return
        }
        
        webView.loadHTMLString(html, baseURL: nil)
    }

    
    @IBAction func rightBarButtonAction(sender: AnyObject) {
    }
    
}

