//
//  ViewController.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DUAReaderDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    
    var msettingView = UIView()
    var mreader: DUAReader!
    var indicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var curPage = 0
    var curChapter = 0
    var curChapterTotalPages = 0
    var curBookName = ""
    var chapterTitles: [String] = []
    var sideBar: UIView?
    var dataArray: [String] = []
    var marksArray: [String: [String: [Int]]] = [:]
    
    
    
    @IBAction func onBtn1Clicked(_ sender: Any) {
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        let bookPath = Bundle.main.path(forResource: "郭黄之恋", ofType: "txt")
        mreader.readWith(filePath: bookPath!, pageIndex: 1)
        
//        记录阅读的书，demo使用
        curBookName = "郭黄之恋"
    
    }
    
    @IBAction func onBtn2Clicked(_ sender: Any) {
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        configuration.bookType = .epub
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        let epubPath = Bundle.main.path(forResource: "每天懂一点好玩心理学", ofType: "epub")
        mreader.readWith(filePath: epubPath!, pageIndex: 1)
        
//        记录阅读的书，demo使用
        curBookName = "每天懂一点好玩心理学"

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chapterTitles = [""]
        indicatorView.center = CGPoint(x: 0.5*self.view.width, y: 0.5*self.view.height)
        indicatorView.hidesWhenStopped = true
        
    }

    //    MARK:--侧边栏
    func showSideBar() -> Void {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        
        msettingView.removeFromSuperview()
        self.sideBar = UIView.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let dirBtn = UIButton.init(frame: CGRect(x: 0, y: 0, width: width/4, height: 30))
        let markBtn = UIButton.init(frame: CGRect(x: width/4, y: 0, width: width/4, height: 30))
        dirBtn.setTitle("目录", for: UIControlState.normal)
        dirBtn.backgroundColor = UIColor.black
        dirBtn.alpha = 0.8
        dirBtn.setTitleColor(UIColor.white, for: .normal)
        dirBtn.setTitleColor(UIColor.blue, for: .selected)
        dirBtn.addTarget(self, action: #selector(onDirBtnClicked(sender:)), for: .touchUpInside)
        
        markBtn.setTitle("书签", for: .normal)
        markBtn.backgroundColor = UIColor.black
        markBtn.alpha = 0.8
        markBtn.setTitleColor(UIColor.white, for: .normal)
        markBtn.setTitleColor(UIColor.blue, for: .selected)
        markBtn.setTitleColor(UIColor.red, for: UIControlState.highlighted)
        markBtn.addTarget(self, action: #selector(onMarkBtnClicked(sender:)), for: .touchUpInside)
        
        let lineH = UIView(frame: CGRect(x: 0, y: 30, width: width/2, height: 1))
        let lineV = UIView(frame: CGRect(x: width/4, y: 0, width: 1, height: 30))
        lineV.backgroundColor = UIColor.white
        lineH.backgroundColor = .white
        
        dataArray = chapterTitles
        let tableView = UITableView.init(frame: CGRect(x: 0, y: 30, width: sideBar!.width/2, height: sideBar!.height - 30))
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.black
        tableView.alpha = 0.8
        tableView.separatorStyle = .none
        
        let window: UIWindow = ((UIApplication.shared.delegate?.window)!)!
        window.addSubview(sideBar!)
        sideBar?.addSubview(dirBtn)
        sideBar?.addSubview(markBtn)
        sideBar?.addSubview(tableView)
        sideBar?.addSubview(lineH)
        sideBar?.addSubview(lineV)


        UIView.animate(withDuration: 0.2, animations: {() in
            self.sideBar?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }, completion: {(complete) in

        })
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(onSideViewClicked(ges:)))
        tap.delegate = self
        sideBar?.addGestureRecognizer(tap)
        
    }

    @objc func onSideViewClicked(ges: UITapGestureRecognizer) -> Void {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        UIView.animate(withDuration: 0.2, animations: {() in
            self.sideBar?.frame = CGRect(x: -width, y: 0, width: width, height: height)
        }, completion: {(complete) in
            self.sideBar?.removeFromSuperview()
        })
    }
    
    @objc func onDirBtnClicked(sender: UIButton) -> Void {
        var table: UITableView = UITableView()
        for item in sideBar!.subviews {
            if item is UIButton {
                (item as! UIButton).setTitleColor(UIColor.white, for: .normal)
            }
            if item is UITableView {
                table = item as! UITableView
            }
        }
        sender.setTitleColor(UIColor.red, for: .normal)
        dataArray = chapterTitles
        table.tag = 0
        table.reloadData()
    }
    
    @objc func onMarkBtnClicked(sender: UIButton) -> Void {
        var table: UITableView = UITableView()

        for item in sideBar!.subviews {
            if item is UIButton {
                (item as! UIButton).setTitleColor(UIColor.white, for: .normal)
            }
            if item is UITableView {
                table = item as! UITableView
            }
        }
        sender.setTitleColor(UIColor.red, for: .normal)

        table.tag = 100
        dataArray = []
        let marks = marksArray[curBookName]
        var markList: [String: [Int]] = [:]
        if marks != nil {
            markList = marks!
        }
        if markList.isEmpty == false {
            for key in markList.keys {
                for item in markList[key]! {
                    let itemString = "第\(key)章 第\(item)页"
                    dataArray.append(itemString)
                }
            }
        }
        
        table.reloadData()
    }
    
    func saveBookMarks(button: UIButton) -> Void {
        let bookMarkBtn = button as! BookMarkButton
        if bookMarkBtn.isClicked {
            bookMarkBtn.isClicked = false
        }else {
            bookMarkBtn.isClicked = true
        }
        let marks = marksArray[curBookName]
        var markList: [String: [Int]] = [:]
        if marks != nil {
            markList = marks!
        }
        if markList.isEmpty {
            markList[String(curChapter)] = [curPage]
        }else {
            if bookMarkBtn.isClicked {
//                写入新书签
                for key in markList.keys {
                    if Int(key) == curChapter {
                        if markList[key]!.contains(curPage) == false {
                            markList[key]!.append(curPage)
                            break
                        }
                    }
                }
                if markList.keys.contains(String(curChapter)) == false {
                    markList[String(curChapter)] = [curPage]
                }
            }else {
//                移除旧书签
                for (index, item) in markList[String(curChapter)]!.enumerated() {
                    if item == curPage {
                        markList[String(curChapter)]?.remove(at: index)
                        break
                    }
                }
            }
        }
        if markList[String(curChapter)]!.isEmpty {
            markList.removeValue(forKey: String(curChapter))
        }
        marksArray[curBookName] = markList
        
        // !!!注：这里书签只保存在内存，实际应用应当缓存在本地，只需将MarkList序列化一下即可
        
    }
    
    //    MARK:--设置面板操作
    
    @objc func onSettingViewClicked(ges: UITapGestureRecognizer) -> Void {
        let topMenu: UIView = msettingView.subviews.first!
        let bottomMenu: UIView = msettingView.subviews.last!
        
        UIView.animate(withDuration: 0.2, animations: {() in
            topMenu.frame = CGRect(x: 0, y: -80, width: self.view.width, height: 80)
            bottomMenu.frame = CGRect(x: 0, y: self.view.height, width: self.view.width, height: 200)
        }, completion: {(complete) in
            if complete {
                self.msettingView.removeFromSuperview()
            }
        })
        

    }
    
    @objc func sliderValueChanged(sender: UISlider) -> Void {
        let index = floor(Float(curChapterTotalPages) * sender.value)
        mreader.readChapterBy(index: curChapter, pageIndex: Int(index))
    }

    
    /// 设置面板点击操作
    ///
    /// - Parameter button: 点击的button
    /// - Discuss: 绝大部分设置均是通过设置reader的配置类config的属性来控制reader的行为的
    @objc func onSettingItemClicked(button: UIButton) {
        switch button.tag {
//            上菜单
        case 100:
            print("退出阅读器")
            mreader.dismiss(animated: true, completion: nil)
            mreader = nil
            msettingView.removeFromSuperview()
        case 101:
            print("书签")
            self.saveBookMarks(button: button)
            
//            下菜单
        case 200:
            print("切换上一章")
            mreader.readChapterBy(index: curChapter - 1, pageIndex: 1)
        case 201:
            print("切换下一章")
            mreader.readChapterBy(index: curChapter + 1, pageIndex: 1)
        case 202:
            print("仿真翻页")
            mreader.config.scrollType = .curl
        case 203:
            print("平移翻页")
            mreader.config.scrollType = .horizontal
        case 204:
            print("竖向滚动翻页")
            mreader.config.scrollType = .vertical
        case 205:
            print("无动画翻页")
            mreader.config.scrollType = .none
        case 206:
            print("设置背景1")
            mreader.config.backgroundImage = UIImage.init(named: "backImg.jpg")
        case 207:
            print("设置背景2")
            mreader.config.backgroundImage = UIImage.init(named: "backImg1.jpg")
        case 208:
            print("设置背景3")
            mreader.config.backgroundImage = UIImage.init(named: "backImg2.jpg")
        case 209:
            print("展示章节目录")
            self.showSideBar()
        case 210:
            print("调小字号")
            mreader.config.fontSize -= 1
        case 211:
            print("调大字号")
            mreader.config.fontSize += 1
        default:
            print("nothing")
        }
    }
    
    //    MARK:--reader delegate
    
    func readerDidClickSettingFrame(reader: DUAReader) {
        let topMenuNibViews = Bundle.main.loadNibNamed("topMenu", owner: nil, options: nil)
        let topMenu = topMenuNibViews?.first as? UIView
        topMenu?.frame = CGRect(x: 0, y: -80, width: self.view.width, height: 80)
        let bottomMenuNibViews = Bundle.main.loadNibNamed("bottomMenu", owner: nil, options: nil)
        let bottomMenu = bottomMenuNibViews?.first as? UIView
        bottomMenu?.frame = CGRect(x: 0, y: self.view.height, width: self.view.width, height: 200)
        let window: UIWindow = ((UIApplication.shared.delegate?.window)!)!
        let baseView = UIView(frame: window.bounds)
        window.addSubview(baseView)
        baseView.addSubview(topMenu!)
        baseView.addSubview(bottomMenu!)
        
        UIView.animate(withDuration: 0.2, animations: {() in
            topMenu?.frame = CGRect(x: 0, y: 0, width: self.view.width, height: 80)
            bottomMenu?.frame = CGRect(x: 0, y: self.view.height - 200, width: self.view.width, height: 200)
        })
//        添加手势
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(onSettingViewClicked(ges:)))
        baseView.addGestureRecognizer(tap)
        msettingView = baseView
        
//        给设置面板所有button添加点击事件
        for view in topMenu!.subviews.first!.subviews {
            if view is UIButton {
                let button = view as! UIButton
                button.addTarget(self, action: #selector(onSettingItemClicked(button:)), for: UIControlEvents.touchUpInside)
            }
        }
        for view in bottomMenu!.subviews.first!.subviews {
            if view is UIButton {
                let button = view as! UIButton
                button.addTarget(self, action: #selector(onSettingItemClicked(button:)), for: UIControlEvents.touchUpInside)
            }
            if view is UISlider {
                let slider = view as! UISlider
                slider.value = Float(curPage) / Float(curChapterTotalPages)
                slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: UIControlEvents.valueChanged)
            }
        }
        
//        查询历史书签
        for view in topMenu!.subviews.first!.subviews {
            if view is BookMarkButton {
                let button = view as! BookMarkButton
                let marks = marksArray[curBookName]
                var markList: [String: [Int]] = [:]
                if marks != nil {
                    markList = marks!
                }
                let chapterMarks = markList[String(curChapter)]
                if chapterMarks != nil {
                    if chapterMarks!.contains(curPage) {
                        button.isClicked = true
                    }
                }
            }
        }
    }
    
    func reader(reader: DUAReader, readerStateChanged state: DUAReaderState) {
        switch state {
        case .busy:
            reader.view.addSubview(indicatorView)
            indicatorView.startAnimating()
        case .ready:
            indicatorView.stopAnimating()
            indicatorView.removeFromSuperview()
        }
    }
    
    func reader(reader: DUAReader, readerProgressUpdated curChapter: Int, curPage: Int, totalPages: Int) {
        self.curPage = curPage
        self.curChapter = curChapter
        self.curChapterTotalPages = totalPages
    }
    
    func reader(reader: DUAReader, chapterTitles: [String]) {
        self.chapterTitles = chapterTitles
    }
    
    
    //    MARK:--table view delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reader.demo.cell")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "reader.demo.cell")
            cell?.backgroundColor = UIColor.clear
        }else {
            for item in cell!.contentView.subviews {
                item.removeFromSuperview()
            }
        }
        let label = UILabel(frame: (cell?.bounds)!)
        label.text = dataArray[indexPath.row]
        label.textColor = UIColor.white
        cell?.contentView.addSubview(label)
        
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag != 0 {
            let cellText = self.dataArray[indexPath.row]
            let texts = cellText.split(separator: " ")
            let chapterStr = String(texts.first!)
            let chapterIndex = Int(String(chapterStr[chapterStr.index(chapterStr.startIndex, offsetBy: 1)]))
            let pageStr = String(texts.last!)
            let pageIndex = Int(String(pageStr[pageStr.index(pageStr.startIndex, offsetBy: 1)]))
            mreader.readChapterBy(index: chapterIndex!, pageIndex: pageIndex!)
            sideBar?.removeFromSuperview()
            return
        }
        mreader.readChapterBy(index: indexPath.row + 1, pageIndex: 1)
        sideBar?.removeFromSuperview()
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: sideBar)
        let rect = CGRect(x: 0, y: 0, width: sideBar!.width/2, height: sideBar!.height)
        if rect.contains(point) {
            return false
        }
        return true
    }
}




