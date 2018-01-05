//
//  DUAStatusBar.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit

class DUAStatusBar: UIView {

    var totalPageCounts = 1
    {
        didSet {
            let text = "第" + String(curPageIndex) + "/" + String(totalPageCounts) + "页"
            label.textAlignment = .center
            label.text = text
            label.textColor = UIColor.gray
            label.font = UIFont.systemFont(ofSize: 11)
            label.sizeToFit()
        }
    }
    var curPageIndex = 1
    {
        didSet {
            let text = "第" + String(curPageIndex + 1) + "/" + String(totalPageCounts) + "页"
            label.textAlignment = .center
            label.text = text
            label.textColor = UIColor.gray
            label.font = UIFont.systemFont(ofSize: 11)
            label.sizeToFit()
        }
    }
    
     var label = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.origin = CGPoint(x: self.width - label.bounds.size.width, y: 3)
 
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
