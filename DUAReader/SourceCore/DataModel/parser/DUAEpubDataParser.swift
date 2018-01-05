//
//  DUAEpubDataParser.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/27.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit
import DTCoreText

class DUAEpubDataParser: DUADataParser {
    
    override func parseChapterFromBook(path: String, completeHandler: @escaping (Array<String>, Array<DUAChapterModel>) -> Void) {
        let epubZippedPath = DUAUtils.unzipWith(filePath: path)
        let opfPath = DUAUtils.OPFPathFrom(epubPath: epubZippedPath)
        let chapterInfoArray = DUAUtils.parseOPF(opfPath: opfPath)
        var titleArray: [String] = []
        var models: [DUAChapterModel] = []
        
        var chapterIndexOffset = false
        if Int(chapterInfoArray.first!["chapterIndex"]!)! == 0 {
            chapterIndexOffset = true
        }
        
        for item in chapterInfoArray {
            titleArray.append(item["chapterTitle"]!)
            let chapter = DUAChapterModel()
            chapter.chapterIndex = chapterIndexOffset ? Int(item["chapterIndex"]!)! + 1 : Int(item["chapterIndex"]!)!
            chapter.path = item["chapterPath"]
            chapter.title = item["chapterIndex"]
            models.append(chapter)
        }
        completeHandler(titleArray, models)
    }
    
    override func attributedStringFromChapterModel(chapter: DUAChapterModel, config: DUAConfiguration) -> NSAttributedString? {
        let htmlData = try? Data.init(contentsOf: URL.init(fileURLWithPath: chapter.path!))
        if htmlData == nil {
            return nil
        }

        let options = [
            DTDefaultFontFamily : "Times New Roman",
            DTDefaultLinkColor  : "purple",
            NSTextSizeMultiplierDocumentOption : 1.0,
            DTDefaultFontSize   : config.fontSize,
            DTDefaultLineHeightMultiplier : config.lineHeightMutiplier,
            DTDefaultTextAlignment : "0",
            DTDefaultHeadIndent : "0.0",
            NSBaseURLDocumentOption : URL.init(fileURLWithPath: chapter.path!),
            DTMaxImageSize      : config.contentFrame.size,
            ] as [String : Any]
        let attrString: NSAttributedString? = NSAttributedString.init(htmlData: htmlData, options: options, documentAttributes: nil)
        
        return attrString
    }
}
