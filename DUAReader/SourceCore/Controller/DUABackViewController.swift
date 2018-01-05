//
//  DUABackViewController.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit

class DUABackViewController: UIViewController {

    var index: Int = 1
    var chapterBelong: Int = 1
    var backImage: UIImage?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageView = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.view.width, height: self.view.height))
        imageView.image = self.backImage
        self.view.addSubview(imageView)
    }
    
    func grabViewController(viewController: DUAPageViewController) -> Void {
        self.index = viewController.index
        self.chapterBelong = viewController.chapterBelong
        let rect = viewController.view.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let transform = CGAffineTransform(a: -1.0, b: 0.0, c: 0.0, d: 1.0, tx: rect.size.width, ty: 0.0)
        context?.concatenate(transform)
        viewController.view.layer.render(in: context!)
        self.backImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
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
