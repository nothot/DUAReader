//
//  DUADataParser.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit
import DTCoreText

class DUADataParser: NSObject {

    func parseChapterFromBook(path: String, completeHandler: @escaping (Array<String>, Array<DUAChapterModel>) -> Void) {
        
    }
    
    func attributedStringFromChapterModel(chapter: DUAChapterModel, config: DUAConfiguration) -> NSAttributedString? {
        return nil
    }
    
    func cutPageWith(attrString: NSAttributedString, config: DUAConfiguration, completeHandler: (Int, DUAPageModel, Bool) -> Void) -> Void {
        let layouter = DTCoreTextLayouter.init(attributedString: attrString)
        let rect = CGRect(x: config.contentFrame.origin.x, y: config.contentFrame.origin.y, width: config.contentFrame.size.width, height: config.contentFrame.size.height - 5)
        var frame = layouter?.layoutFrame(with: rect, range: NSRange(location: 0, length: attrString.length))
        
        var pageVisibleRange = frame?.visibleStringRange()
        var rangeOffset = pageVisibleRange!.location + pageVisibleRange!.length
        var count = 1
        
        while rangeOffset <= attrString.length && rangeOffset != 0 {
            let pageModel = DUAPageModel.init()
            pageModel.attributedString = attrString.attributedSubstring(from: pageVisibleRange!)
            pageModel.range = pageVisibleRange
            pageModel.pageIndex = count - 1
            
            frame = layouter?.layoutFrame(with: rect, range: NSRange(location: rangeOffset, length: attrString.length - rangeOffset))
            pageVisibleRange = frame?.visibleStringRange()
            if pageVisibleRange == nil {
                rangeOffset = 0
            }else {
                rangeOffset = pageVisibleRange!.location + pageVisibleRange!.length
            }
            
            let completed = (rangeOffset <= attrString.length && rangeOffset != 0) ? false : true
            completeHandler(count, pageModel, completed)
            count += 1
        }
    }
    
}
