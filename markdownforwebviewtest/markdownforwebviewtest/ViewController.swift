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
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        webView.scrollView.scrollEnabled = false
        
        var frame = webView.frame
        frame.origin.x = 0
        frame.origin.y = 0
        frame.size.width = UIScreen.mainScreen().bounds.width
        webView.frame = frame
        
        scrollView.addSubview(webView)
    }
    
    
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("load \(request)")
        print("start: \(webView.scrollView.contentSize)")
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("finish")
        print("end: \(webView.scrollView.contentSize)")
        webView.sizeToFit()
        let height = Double(webView.stringByEvaluatingJavaScriptFromString("document.body.scrollHeight") ?? "0") ?? 0
        webView.frame.size = CGSizeMake(375, CGFloat(height))
        scrollView.contentSize = CGSizeMake(375, CGFloat(height))
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
        print(html)
        webView.loadHTMLString(html, baseURL: nil)
    }

    
    @IBAction func rightBarButtonAction(sender: AnyObject) {
        UIGraphicsBeginImageContextWithOptions(webView.frame.size, true, UIScreen.mainScreen().scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("无法获取context")
            return
        }
        webView.layer.renderInContext(context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let vc = storyboard?.instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
        vc.image = image
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

