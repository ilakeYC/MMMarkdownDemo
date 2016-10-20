//
//  ImageViewController.swift
//  markdownforwebviewtest
//
//  Created by LakesMac on 2016/10/20.
//  Copyright © 2016年 Dabllo. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    var image: UIImage?
    let imageView = UIImageView(frame: .zero)
    
    @IBOutlet weak var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let image = image else {
            return
        }
        
        imageView.image = image
        imageView.frame.size = image.size
        scrollView.addSubview(imageView)
        scrollView.contentSize = image.size
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
