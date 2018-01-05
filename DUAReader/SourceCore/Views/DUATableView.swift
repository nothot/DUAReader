//
//  DUATableView.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/28.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit

enum tableViewScrollDirecton {
    case up
    case down
    case unknown
}

class DUATableView: UITableView {

    var dataArray: [DUAPageModel] = []
    var cellIndex: Int = 0
    var isReloading = false
    var arrivedZeroOffset = false
    var scrollDirection = tableViewScrollDirecton.unknown
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
