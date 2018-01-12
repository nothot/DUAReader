//
//  BookMarkButton.swift
//  DUAReader
//
//  Created by mengminduan on 2018/1/12.
//  Copyright © 2018年 nothot. All rights reserved.
//

import UIKit

class BookMarkButton: UIButton {

    
    var isClicked = false {
        didSet {
            if isClicked {
                self.setImage(UIImage.init(named: "bookMarked"), for: .normal)
            }else {
                setImage(UIImage.init(named: "bookMark"), for: .normal)
            }
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
