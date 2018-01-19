//
//  DUAConVexLensView.swift
//  DUAReader
//
//  Created by mengminduan on 2018/1/18.
//  Copyright © 2018年 nothot. All rights reserved.
//

import UIKit

class DUAConVexLensView: UIView {
    
    var locatePoint: CGPoint = CGPoint() {
        didSet {
            self.center = CGPoint(x: locatePoint.x, y: locatePoint.y - 80)
            self.setNeedsDisplay()
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.cornerRadius = 60
        self.layer.masksToBounds = true
    }
    
    init() {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        
        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.cornerRadius = 60
        self.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {

        let ctx = UIGraphicsGetCurrentContext()

        ctx?.translateBy(x: self.frame.width/2, y: self.frame.height/2)
        ctx?.scaleBy(x: 1.5, y: 1.5)
        ctx?.translateBy(x: -1 * locatePoint.x, y: -1 * (locatePoint.y + 20))
        UIApplication.shared.keyWindow?.layer.render(in: ctx!)
    }

}
