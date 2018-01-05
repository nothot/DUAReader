//
//  ViewController.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DUAReaderDelegate {
    
    var msettingView = UIView()
    var mreader: DUAReader!
    var indicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    var curPage = 0
    var curChapter = 0
    
    
    
    
    @IBAction func onBtn1Clicked(_ sender: Any) {
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        configuration.scrollType = .vertical
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        
        let bookPath = Bundle.main.path(forResource: "郭黄之恋", ofType: "txt")
        mreader.readWith(filePath: bookPath!, pageIndex: 1)
    
    }
    
    @IBAction func onBtn2Clicked(_ sender: Any) {
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        configuration.scrollType = .vertical
        configuration.bookType = .epub
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        
//        let epubPath = Bundle.main.path(forResource: "卑鄙的圣人：曹操", ofType: "epub")
        let epubPath = Bundle.main.path(forResource: "图文天下·中国通史", ofType: "epub")
//        let epubPath = Bundle.main.path(forResource: "每天懂一点好玩心理学", ofType: "epub")
        mreader.readWith(filePath: epubPath!, pageIndex: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        indicatorView.center = CGPoint(x: 0.5*self.view.width, y: 0.5*self.view.height)
        indicatorView.hidesWhenStopped = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    
    @objc func onSettingItemClicked(button: UIButton) {
        switch button.tag {
//            上菜单
        case 100:
            mreader.dismiss(animated: true, completion: nil)
            mreader = nil
            msettingView.removeFromSuperview()
        case 101:
            print("书签")
            
//            下菜单
        case 200:
            print("切换上一章")
            mreader.readChapterBy(index: curChapter - 1)
        case 201:
            print("切换下一章")
            mreader.readChapterBy(index: curChapter + 1)
        case 202:
            mreader.config.scrollType = .curl
        case 203:
            print("覆盖动画")
        case 204:
            mreader.config.scrollType = .vertical
        case 205:
            print("无翻页动画")
        case 206:
            mreader.config.backgroundImage = UIImage.init(named: "backImg.jpg")
        case 207:
            mreader.config.backgroundImage = UIImage.init(named: "backImg1.jpg")
        case 208:
            mreader.config.backgroundImage = UIImage.init(named: "backImg2.jpg")
        case 209:
            print("章节目录")
        case 210:
            mreader.config.fontSize -= 1
        case 211:
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
    
    func reader(reader: DUAReader, readerProgressUpdated curChapter: Int, curPage: Int) {
        self.curPage = curPage
        self.curChapter = curChapter
    }
    
}

