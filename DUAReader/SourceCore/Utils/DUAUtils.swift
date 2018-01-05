//
//  DUAUtils.swift
//  DUAReader
//
//  Created by mengminduan on 2018/1/3.
//  Copyright © 2018年 nothot. All rights reserved.
//

import UIKit
import ZipArchive
import TouchXML

class DUAUtils: NSObject {

    /// 解压文件
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 解压目录
    class func unzipWith(filePath: String) -> String {
        let zipHandler = ZipArchive.init()
        let newPath: NSString = filePath as NSString
        let fileName = newPath.lastPathComponent.split(separator: ".").first
        if zipHandler.unzipOpenFile(filePath) {
            let zipDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + String(fileName!)
            if FileManager.default.fileExists(atPath: zipDir) {
                try? FileManager.default.removeItem(atPath: zipDir)
            }
            if zipHandler.unzipFile(to: zipDir, overWrite: true) {
                return zipDir
            }
        }
        return ""
    }

    /// 获取OPF文件路径
    ///
    /// - Parameter epubPath: epub解压后目录
    /// - Returns: OPF文件路径
    class func OPFPathFrom(epubPath: String) -> String {
        let containerPath = epubPath + "/META-INF/container.xml"
        if FileManager.default.fileExists(atPath: containerPath) {
            let document = try? CXMLDocument.init(contentsOf: URL.init(fileURLWithPath: containerPath), options: 0)
            let opfPathNode: CXMLNode = try! document?.nodes(forXPath: "//@full-path").first as! CXMLNode
            let opfObselutePath = epubPath + "/" + opfPathNode.stringValue()
            return opfObselutePath
        }

        return ""
    }
    
    /// 解析OPF文件
    ///
    /// - Parameter opfPath: OPF文件路径
    /// - Returns: 字典数组，包含解析得到的章节信息
    class func parseOPF(opfPath: String) -> [[String: String]] {
        let document = try! CXMLDocument.init(contentsOf: URL.init(fileURLWithPath: opfPath), options: 0)
        let itemArray: [CXMLElement] = try! document.nodes(forXPath: "//opf:item", namespaceMappings: ["opf":"http://www.idpf.org/2007/opf"]) as! [CXMLElement]
        var ncxFileName = ""
        var itemDict: [String: String] = [:]
        for item in itemArray {
            itemDict[item.attribute(forName: "id").stringValue()] = item.attribute(forName: "href").stringValue()
            if item.attribute(forName: "media-type").stringValue() == "application/x-dtbncx+xml" {
                ncxFileName = item.attribute(forName: "href").stringValue()
            }
        }
        
        let opfParentPath = self.getparentPathFrom(path: opfPath)
        let ncxFilePath = opfParentPath + "/\(ncxFileName)"
        let ncxDocument = try! CXMLDocument.init(contentsOf: URL.init(fileURLWithPath: ncxFilePath), options: 0)
        var titleDict: [String: String] = [:]
        for item in itemArray {
            let href = item.attribute(forName: "href").stringValue()
            var xpath = "//ncx:content[@src='\(href!)']/../ncx:navLabel/ncx:text"
            var navPoints = try? ncxDocument.nodes(forXPath: xpath, namespaceMappings: ["ncx":"http://www.daisy.org/z3986/2005/ncx/"])
            if navPoints!.isEmpty {
                let contents = try! ncxDocument.nodes(forXPath: "//ncx:content", namespaceMappings: ["ncx":"http://www.daisy.org/z3986/2005/ncx/"])
                for element in contents {
                    let contentElement = element as! CXMLElement
                    let src = contentElement.attribute(forName: "src").stringValue()
                    if src!.hasPrefix(href!) {
                        xpath = "//ncx:content[@src='\(src!)']/../ncx:navLabel/ncx:text"
                        navPoints = try? ncxDocument.nodes(forXPath: xpath, namespaceMappings: ["ncx":"http://www.daisy.org/z3986/2005/ncx/"])
                        break
                    }
                }
            }
            
            if navPoints!.isEmpty == false {
                let titleElement = navPoints?.first as! CXMLElement
                titleDict[href!] = titleElement.stringValue()
            }
        }
        
        let itemRefArray = try! document.nodes(forXPath: "//opf:itemref", namespaceMappings: ["opf":"http://www.idpf.org/2007/opf"])
        var chapterArray: [[String: String]] = []
        for (index, item) in itemRefArray.enumerated() {
            let itemRef = item as! CXMLElement
            let chapterRef = itemDict[itemRef.attribute(forName: "idref").stringValue()]
            let chapterPath = self.getparentPathFrom(path: opfPath) + "/\(chapterRef!)"
            var chapterDict: [String: String] = [:]
            chapterDict["chapterIndex"] = String(index)
            chapterDict["chapterTitle"] = titleDict[chapterRef!]
            chapterDict["chapterPath"] = chapterPath
            chapterArray.append(chapterDict)
        }
        return chapterArray
    }
    
    class func getparentPathFrom(path: String) -> String {
        var components = path.split(separator: "/")
        components.removeLast()
        var parentPath: String = ""
        for item in components {
            parentPath.append("/")
            parentPath.append(String(item))
        }
        return parentPath
    }
    
    
}

