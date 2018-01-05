//
//  DUAReader.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/26.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit
import DTCoreText

enum DUAReaderState {
    case busy
    case ready
}

protocol DUAReaderDelegate: NSObjectProtocol {
    func readerDidClickSettingFrame(reader: DUAReader) -> Void
    func reader(reader: DUAReader, readerStateChanged state: DUAReaderState) -> Void
    func reader(reader: DUAReader, readerProgressUpdated curChapter: Int, curPage: Int, totalPages: Int) -> Void
    func reader(reader: DUAReader, chapterTitles: [String]) -> Void
    
}

class DUAReader: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    public var config: DUAConfiguration!
    
    public var delegate: DUAReaderDelegate?
    
    private var chapterCaches: [String: [DUAPageModel]] = [String: [DUAPageModel]]()
    
    private var chapterModels = [String: DUAChapterModel]()
    
    private var dataParser: DUADataParser = DUADataParser()
    
    private var cacheQueue: DispatchQueue = DispatchQueue(label: "duareader.cache.queue")
    
    private var pageVC: DUAContainerPageViewController?
    
    private var tableView: DUATableView?
    
    private var statusBar: DUAStatusBar?
    
    private var isReCutPage: Bool = false
    
    private var currentPageIndex: Int = 1
    
    private var currentChapterIndex: Int = 0
    
    private var prePageStartLocation: Int = -1
    
    private var state: DUAReaderState = DUAReaderState.ready
    
    private var firstIntoReader = true
    
    private var pageHunger = false
    
    private var totalChapterModels: [DUAChapterModel] = []
    
    private var statusBarForTableView: DUAStatusBar?
    
    var successSwitchChapter = 0
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //    MARK:--对外接口
    public func readWith(filePath: String, pageIndex: Int) -> Void {
        
        self.postReaderStateNotification(state: .busy)
        self.dataParser.parseChapterFromBook(path: filePath, completeHandler: {(titles, models) -> Void in
            if self.delegate?.reader(reader: chapterTitles: ) != nil {
                self.delegate?.reader(reader: self, chapterTitles: titles)
            }
            self.totalChapterModels = models
            self.readWith(chapter: models.first!, pageIndex: pageIndex)
        })
        
    }
    
    public func readChapterBy(index: Int, pageIndex: Int) -> Void {
        if index > 0 && index <= totalChapterModels.count {
            if self.pageArrayFromCache(chapterIndex: index).isEmpty {
                successSwitchChapter = index
                self.postReaderStateNotification(state: .busy)
                self.requestChapterWith(index: index)
            }else {
                successSwitchChapter = 0
                currentPageIndex = pageIndex <= 0 ? 0 : (pageIndex - 1)
                self.updateChapterIndex(index: index)
                self.loadPage(pageIndex: currentPageIndex)
                if self.delegate?.reader(reader: readerProgressUpdated: curPage: totalPages: ) != nil {
                    self.delegate?.reader(reader: self, readerProgressUpdated: currentChapterIndex, curPage: currentPageIndex + 1, totalPages: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count)
                }
            }
        }
    }
    
    //    MARK:--custom method
    private func readWith(chapter: DUAChapterModel, pageIndex: Int) -> Void {
        
        chapterModels[String(chapter.chapterIndex)] = chapter
        if Thread.isMainThread == false {
            self.forwardCacheWith(chapter: chapter)
            return
        }
        
        var pageModels: [DUAPageModel] = [DUAPageModel]()
        if self.isReCutPage {
            self.postReaderStateNotification(state: .busy)
            self.chapterCaches.removeAll()
        }else {
            pageModels = self.pageArrayFromCache(chapterIndex: chapter.chapterIndex)
        }
        if pageModels.isEmpty || self.isReCutPage {
            self.cacheQueue.async {
                if self.pageArrayFromCache(chapterIndex: chapter.chapterIndex).isEmpty == false {
                    return
                }
                let attrString = self.dataParser.attributedStringFromChapterModel(chapter: chapter, config: self.config)
                self.dataParser.cutPageWith(attrString: attrString!, config: self.config, completeHandler: {
                    (completedPageCounts, page, completed) -> Void in
                    pageModels.append(page)
                    if completed {
                        self.cachePageArray(pageModels: pageModels, chapterIndex: chapter.chapterIndex)
                        DispatchQueue.main.async {
                            self.processPageArray(pages: pageModels, chapter: chapter, pageIndex: pageIndex)
                        }
                        
                    }
                })
            }
        }
        
        
    }
    
    private func processPageArray(pages: [DUAPageModel], chapter: DUAChapterModel, pageIndex: Int) -> Void {
        
        self.postReaderStateNotification(state: .ready)
        if pageHunger {
            pageHunger = false
            if pageVC != nil {
                self.loadPage(pageIndex: currentPageIndex)
            }
            if tableView != nil {
                if currentPageIndex == 0 && tableView?.scrollDirection == .up {
                    self.requestLastChapterForTableView()
                }
                if currentPageIndex == self.pageArrayFromCache(chapterIndex: currentChapterIndex).count - 1 && tableView?.scrollDirection == .down {
                    self.requestNextChapterForTableView()
                }
            }
        }
        
        if firstIntoReader {
            firstIntoReader = false
            currentPageIndex = pageIndex <= 0 ? 0 : (pageIndex - 1)
            updateChapterIndex(index: chapter.chapterIndex)
            self.loadPage(pageIndex: currentPageIndex)
            if self.delegate?.reader(reader: readerProgressUpdated: curPage: totalPages: ) != nil {
                self.delegate?.reader(reader: self, readerProgressUpdated: currentChapterIndex, curPage: currentPageIndex + 1, totalPages: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count)
            }
        }
        
        if isReCutPage {
            isReCutPage = false
            var newIndex = 1
            for (index, item) in pages.enumerated() {
                if prePageStartLocation >= (item.range?.location)! && prePageStartLocation <= (item.range?.location)! + (item.range?.length)! {
                    newIndex = index
                }
            }
            currentPageIndex = newIndex
            self.loadPage(pageIndex: currentPageIndex)
            
//            触发预缓存
            self.forwardCacheIfNeed(forward: true)
            self.forwardCacheIfNeed(forward: false)
        }
        
        if successSwitchChapter != 0 {
            self.readChapterBy(index: successSwitchChapter, pageIndex: 1)
        }
    }
    
    private func postReaderStateNotification(state: DUAReaderState) -> Void {
        DispatchQueue.main.async {
            if self.delegate?.reader(reader: readerStateChanged: ) != nil {
                self.delegate?.reader(reader: self, readerStateChanged: state)
            }
        }
    }
    
    @objc private func pagingTap(ges: UITapGestureRecognizer) -> Void {
        let tapPoint = ges.location(in: self.view)
        let width = UIScreen.main.bounds.size.width
        let rect = CGRect(x: width/3, y: 0, width: width/3, height: UIScreen.main.bounds.size.height)
        if rect.contains(tapPoint) {
            if self.delegate?.readerDidClickSettingFrame(reader:) != nil {
                self.delegate?.readerDidClickSettingFrame(reader: self)
            }
        }
    }
    
    //    MARK:--UI渲染
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        if self.config.bookType == DUAReaderBookType.epub {
            self.dataParser = DUAEpubDataParser()
        }else {
            self.dataParser = DUATextDataParser()
        }
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(pagingTap(ges:)))
        self.view.addGestureRecognizer(tapGesture)
        self.addObserverForConfiguration()
        self.loadReaderView()
    }
    
    private func loadReaderView() -> Void {
        switch self.config.scrollType {
        case .curl:
            self.loadPageViewController()
        case .vertical:
            self.loadTableView()
        case .horizontal:
            print("nothing")
        }
        if self.config.backgroundImage != nil {
            self.loadBackgroundImage()
        }
    }
    
    private func loadPageViewController() -> Void {
        if self.pageVC != nil {
            self.pageVC?.view.removeFromSuperview()
            self.pageVC?.willMove(toParentViewController: nil)
            self.pageVC?.removeFromParentViewController()
        }
        if self.tableView != nil {
            for item in self.view.subviews {
                item.removeFromSuperview()
            }
        }
        
        let transtionStyle: UIPageViewControllerTransitionStyle = (self.config.scrollType == .curl) ? .pageCurl : .scroll
        self.pageVC = DUAContainerPageViewController(transitionStyle: transtionStyle, navigationOrientation: .horizontal, options: nil)
        self.pageVC?.dataSource = self
        self.pageVC?.delegate = self
        self.pageVC?.view.backgroundColor = UIColor.clear
        self.pageVC?.isDoubleSided = (self.config.scrollType == .curl) ? true : false
        
        self.addChildViewController(self.pageVC!)
        self.view.addSubview((self.pageVC?.view)!)
        self.pageVC?.didMove(toParentViewController: self)
    }
    
    private func loadTableView() -> Void {
        if self.pageVC != nil {
            self.pageVC?.view.removeFromSuperview()
            self.pageVC?.willMove(toParentViewController: nil)
            self.pageVC?.removeFromParentViewController()
        }
        if self.tableView != nil {
            for item in self.view.subviews {
                item.removeFromSuperview()
            }
        }
        self.tableView = DUATableView(frame: CGRect.init(x: 0, y: config.contentFrame.origin.y, width: UIScreen.main.bounds.size.width, height: config.contentFrame.size.height), style: .plain)
        self.tableView!.dataSource = self
        self.tableView!.delegate = self
        self.tableView!.showsVerticalScrollIndicator = false
        self.tableView!.separatorStyle = .none
        self.tableView!.estimatedRowHeight = 0
        self.tableView!.scrollsToTop = false
        self.tableView!.backgroundColor = UIColor.clear

        self.view.addSubview(tableView!)
        
        self.addStatusBarTo(view: self.view, totalCounts: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count, curPage: currentPageIndex)
    }
    
    private func loadPage(pageIndex: Int) -> Void {
        switch self.config.scrollType {
        case .curl:
            let page = self.getPageVCWith(pageIndex: pageIndex, chapterIndex: self.currentChapterIndex)
            if page == nil {
                return
            }
            self.pageVC?.setViewControllers([page!], direction: .forward, animated: false, completion: nil)
        case .vertical:
            print("load table view page")
            tableView?.dataArray.removeAll()
            tableView?.dataArray = self.pageArrayFromCache(chapterIndex: currentChapterIndex)
            self.tableView?.cellIndex = pageIndex
            if tableView?.dataArray == nil {
                return
            }
            
            self.tableView?.isReloading = true
            self.tableView?.reloadData()
            self.tableView?.scrollToRow(at: IndexPath.init(row: tableView!.cellIndex, section: 0), at: UITableViewScrollPosition.top, animated: false)
            self.tableView?.isReloading = false
            
            self.statusBarForTableView?.totalPageCounts = (tableView?.dataArray.count)!
            self.statusBarForTableView?.curPageIndex = currentPageIndex
            
//            当加载的页码为最后一页，需要手动触发一次下一章的请求
            if self.currentPageIndex == self.pageArrayFromCache(chapterIndex: self.currentChapterIndex).count - 1 {
                self.requestNextChapterForTableView()
            }
        case .horizontal:
            print("nothing")
        }
    }
    
    private func loadBackgroundImage() -> Void {
        let curPage = pageVC?.viewControllers?.first as? DUAPageViewController
        if curPage != nil {
            let imageView = curPage?.view.subviews.first as! UIImageView
            imageView.image = self.config.backgroundImage
        }
        let firstView = self.view.subviews.first as? UIImageView
        if firstView != nil {
            firstView?.image = self.config.backgroundImage
        }else {
            let imageView = UIImageView.init(frame: self.view.frame)
            imageView.image = self.config.backgroundImage
            self.view.insertSubview(imageView, at: 0)
        }
    }
    
    private func addStatusBarTo(view: UIView, totalCounts: Int, curPage: Int) -> Void {
        let safeAreaBottomHeight: CGFloat = UIScreen.main.bounds.size.height == 812.0 ? 34 : 0
        let rect = CGRect(x: config.contentFrame.origin.x, y: UIScreen.main.bounds.size.height - 30 - safeAreaBottomHeight, width: config.contentFrame.width, height: 20)
        let statusBar = DUAStatusBar.init(frame: rect)
        view.addSubview(statusBar)
        statusBar.totalPageCounts = totalCounts
        statusBar.curPageIndex = curPage
        self.statusBarForTableView = statusBar
    }
    
    //    MARK:--数据处理
    
    private func getPageVCWith(pageIndex: Int, chapterIndex: Int) -> DUAPageViewController? {
        let page = DUAPageViewController()
        page.index = pageIndex
        page.chapterBelong = chapterIndex
        if self.config.backgroundImage != nil {
            page.backgroundImage = self.config.backgroundImage
        }
        let dtLabel = DTAttributedLabel.init(frame: self.config.contentFrame)
        
        let pageArray = self.pageArrayFromCache(chapterIndex: chapterIndex)
        if pageArray.isEmpty {
            return nil
        }
        let pageModel = pageArray[pageIndex]
        dtLabel.attributedString = pageModel.attributedString
        dtLabel.backgroundColor = UIColor.clear
        page.view.addSubview(dtLabel)
    
        self.addStatusBarTo(view: page.view, totalCounts: pageArray.count, curPage: pageIndex)
        
        return page
    }
    
    private func pageArrayFromCache(chapterIndex: Int) -> [DUAPageModel] {
        if let pageArray = self.chapterCaches[String(chapterIndex)] {
            return pageArray
        }else {
            return []
        }
    }
    
    private func cachePageArray(pageModels: [DUAPageModel], chapterIndex: Int) -> Void {
        self.chapterCaches[String(chapterIndex)] = pageModels
//        for item in self.chapterCaches.keys {
//            if Int(item)! - currentChapterIndex > 2 || Int(item)! - currentChapterIndex < -1 {
//                self.chapterCaches.removeValue(forKey: item)
//            }
//        }
    }
    
    
    private func requestChapterWith(index: Int) -> Void {
        if self.pageArrayFromCache(chapterIndex: index).isEmpty == false {
            return
        }
        let chapter = totalChapterModels[index - 1]
        self.readWith(chapter: chapter, pageIndex: 1)
    }
    
    private func updateChapterIndex(index: Int) -> Void {
        if currentChapterIndex == index {
            return
        }
        print("进入第 \(index) 章")
        let forward = currentChapterIndex > index ? false : true
        currentChapterIndex = index
        self.forwardCacheIfNeed(forward: forward)
    }
    
    private func requestLastChapterForTableView() -> Void {
        tableView?.scrollDirection = .up
        if currentChapterIndex - 1 <= 0 {
            return
        }
        self.requestChapterWith(index: currentChapterIndex - 1)
        let lastPages = self.pageArrayFromCache(chapterIndex: currentChapterIndex - 1)
        if lastPages.isEmpty {
            //                    页面饥饿
            pageHunger = true
            self.postReaderStateNotification(state: .busy)
            return
        }
        var indexPathsToInsert: [IndexPath] = []
        for (index, _) in lastPages.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            indexPathsToInsert.append(indexPath)
        }
        self.tableView?.dataArray = lastPages + (self.tableView?.dataArray)!
        self.tableView?.beginUpdates()
        self.tableView?.insertRows(at: indexPathsToInsert, with: .top)
        self.tableView?.endUpdates()

        DispatchQueue.main.async {
            self.tableView?.cellIndex += lastPages.count
            self.tableView?.setContentOffset(CGPoint.init(x: 0, y: CGFloat.init(lastPages.count)*self.config.contentFrame.height), animated: false)
        }
        
    }
    
    private func requestNextChapterForTableView() -> Void {
        tableView?.scrollDirection = .down
        if currentChapterIndex + 1 > totalChapterModels.count {
            return
        }
        self.requestChapterWith(index: currentChapterIndex + 1)
        let nextPages = self.pageArrayFromCache(chapterIndex: currentChapterIndex + 1)
        if nextPages.isEmpty {
//                    页面饥饿
            pageHunger = true
            self.postReaderStateNotification(state: .busy)
            return
        }
        var indexPathsToInsert: [IndexPath] = []
        for (index, _) in nextPages.enumerated() {
            let indexPath = IndexPath(row: (tableView?.dataArray.count)! + index, section: 0)
            indexPathsToInsert.append(indexPath)
        }
        self.tableView?.dataArray += nextPages
        self.tableView?.beginUpdates()
        self.tableView?.insertRows(at: indexPathsToInsert, with: .none)
        self.tableView?.endUpdates()
    }
    
    //    MARK:--预缓存
    
    private func forwardCacheIfNeed(forward: Bool) -> Void {
        let predictIndex = forward ? currentChapterIndex + 1 : currentChapterIndex - 1
        if predictIndex <= 0 || predictIndex > totalChapterModels.count {
            return
        }
        self.cacheQueue.async {
            let nextPageArray = self.pageArrayFromCache(chapterIndex: predictIndex)
            if nextPageArray.isEmpty {
                print("执行预缓存 章节 \(predictIndex)")
                self.requestChapterWith(index: predictIndex)
            }
        }
    }
    
    private func forwardCacheWith(chapter: DUAChapterModel) -> Void {
        var pageArray: [DUAPageModel] = []
        let attrString = self.dataParser.attributedStringFromChapterModel(chapter: chapter, config: self.config)
        self.dataParser.cutPageWith(attrString: attrString!, config: self.config, completeHandler: {
            (completedPageCounts, page, completed) -> Void in
            pageArray.append(page)
            if completed {
                self.cachePageArray(pageModels: pageArray, chapterIndex: chapter.chapterIndex)
                print("预缓存完成")
                if pageHunger {
                    DispatchQueue.main.async {
                        self.postReaderStateNotification(state: .ready)
                        self.pageHunger = false
                        if self.pageVC != nil {
                            self.loadPage(pageIndex: self.currentPageIndex)
                        }
                        if self.tableView != nil {
                            if self.currentPageIndex == 0 && self.tableView?.scrollDirection == .up {
                                self.requestLastChapterForTableView()
                            }
                            if self.currentPageIndex == self.pageArrayFromCache(chapterIndex: self.currentChapterIndex).count - 1 && self.tableView?.scrollDirection == .down {
                                self.requestNextChapterForTableView()
                            }
                        }
                    }
                }
            }
        })
    }
    
    //    MARK:--属性观察器
    
    private func addObserverForConfiguration() -> Void {
        self.config.didFontSizeChanged = {(fontSize) in
            self.reloadReader()
        }
        self.config.didLineHeightChanged = {(lineHeight) in
            self.reloadReader()
        }
        self.config.didFontNameChanged = {(String) in
            self.reloadReader()
        }
        self.config.didBackgroundImageChanged = {(UIImage) in
            self.loadBackgroundImage()
        }
        self.config.didScrollTypeChanged = {(DUAReaderScrollType) in
            self.loadReaderView()
            self.loadPage(pageIndex: self.currentPageIndex)
        }
    }
    
    private func reloadReader() -> Void {
        isReCutPage = true
        if prePageStartLocation == -1 {
            let pageArray = self.pageArrayFromCache(chapterIndex: currentChapterIndex)
            prePageStartLocation = (pageArray[currentPageIndex].range?.location)!
        }
        let chapter = chapterModels[String(currentChapterIndex)]
        self.readWith(chapter: chapter!, pageIndex: currentPageIndex)
    }
    
    //    MARK:--PageVC Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        print("向前翻页")
        struct FirstPage {
            static var arrived = false
        }
        if viewController is DUAPageViewController {
            let page = viewController as! DUAPageViewController
            let backPage = DUABackViewController()
            var nextIndex = page.index - 1
            if nextIndex < 0 {
                if currentChapterIndex <= 1 {
                    return nil
                }
                FirstPage.arrived = true
                self.pageVC?.willStepIntoLastChapter = true
                self.requestChapterWith(index: currentChapterIndex - 1)
                nextIndex = self.pageArrayFromCache(chapterIndex: currentChapterIndex - 1).count - 1
                let nextPage = self.getPageVCWith(pageIndex: nextIndex, chapterIndex: currentChapterIndex - 1)
                //            需要的页面并没有准备好，此时出现页面饥饿
                if nextPage == nil {
                    self.postReaderStateNotification(state: .busy)
                    pageHunger = true
                    return nil
                }else {
                    backPage.grabViewController(viewController: nextPage!)
                    return backPage
                }
            }
            backPage.grabViewController(viewController: self.getPageVCWith(pageIndex: nextIndex, chapterIndex: page.chapterBelong)!)
            return backPage
        }
        let back = viewController as! DUABackViewController
        if FirstPage.arrived {
            FirstPage.arrived = false
            return self.getPageVCWith(pageIndex: back.index, chapterIndex: back.chapterBelong)
        }
        return self.getPageVCWith(pageIndex: back.index, chapterIndex: back.chapterBelong)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        print("向后翻页")
        struct LastPage {
            static var arrived = false
        }
        let nextIndex: Int
        let pageArray = self.pageArrayFromCache(chapterIndex: currentChapterIndex)
        if viewController is DUAPageViewController {
            let page = viewController as! DUAPageViewController
            nextIndex = page.index + 1
            if nextIndex == pageArray.count {
                LastPage.arrived = true
            }
            let backPage = DUABackViewController()
            backPage.grabViewController(viewController: page)
            return backPage
        }
        if LastPage.arrived {
            LastPage.arrived = false
            if currentChapterIndex + 1 > totalChapterModels.count {
                return nil
            }
            pageVC?.willStepIntoNextChapter = true
            self.requestChapterWith(index: currentChapterIndex + 1)
            let nextPage = self.getPageVCWith(pageIndex: 0, chapterIndex: currentChapterIndex + 1)
//            需要的页面并没有准备好，此时出现页面饥饿
            if nextPage == nil {
                self.postReaderStateNotification(state: .busy)
                pageHunger = true
            }
            return nextPage
        }
        let back = viewController as! DUABackViewController
        return self.getPageVCWith(pageIndex: back.index + 1, chapterIndex: back.chapterBelong)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        prePageStartLocation = -1
        let curPage = pageViewController.viewControllers?.first as! DUAPageViewController
        let previousPage = previousViewControllers.first as! DUAPageViewController
        print("当前页面所在章节 \(curPage.chapterBelong) 先前页面所在章节 \(previousPage.chapterBelong)")
        
        currentPageIndex = curPage.index
        
        let didStepIntoLastChapter = (pageVC?.willStepIntoLastChapter)! && curPage.chapterBelong < previousPage.chapterBelong
        let didStepIntoNextChapter = (pageVC?.willStepIntoNextChapter)! && curPage.chapterBelong > previousPage.chapterBelong
        if didStepIntoNextChapter {
            print("进入下一章")
            updateChapterIndex(index: currentChapterIndex + 1)
            pageVC?.willStepIntoLastChapter = true
            pageVC?.willStepIntoNextChapter = false
        }
        if didStepIntoLastChapter {
            print("进入上一章")
            updateChapterIndex(index: currentChapterIndex - 1)
            pageVC?.willStepIntoNextChapter = true
            pageVC?.willStepIntoLastChapter = false
        }
        
        if currentPageIndex != 0 {
            pageVC?.willStepIntoLastChapter = false
        }
        if currentPageIndex != self.pageArrayFromCache(chapterIndex: currentChapterIndex).count - 1 {
            pageVC?.willStepIntoNextChapter = false
        }
        
//        进度信息必要时可以通过delegate回调出去
        print("当前阅读进度 章节 \(currentChapterIndex) 总页数 \(self.pageArrayFromCache(chapterIndex: currentChapterIndex).count) 当前页 \(currentPageIndex + 1)")
        if self.delegate?.reader(reader: readerProgressUpdated: curPage: totalPages: ) != nil {
            self.delegate?.reader(reader: self, readerProgressUpdated: currentChapterIndex, curPage: currentPageIndex + 1, totalPages: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count)
        }
    }
    
    
    //    MARK:--Table View Delegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return config.contentFrame.height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableView!.dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: DUATableViewCell? = self.tableView?.dequeueReusableCell(withIdentifier: "dua.reader.cell") as? DUATableViewCell
        if let subviews = cell?.contentView.subviews {
            for item in subviews {
                item.removeFromSuperview()
            }
        }
        if cell == nil {
            cell = DUATableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "dua.reader.cell")
        }
        
        let pageModel = self.tableView?.dataArray[indexPath.row]
        cell?.configCellWith(pageModel: pageModel!, config: config)
        
        return cell!
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView!.isReloading {
            return
        }
        if scrollView.contentOffset.y <= 0 {
            scrollView.contentOffset.y = 0
            // cell index = 0 需要请求上一章
            if tableView?.arrivedZeroOffset == false {
                self.requestLastChapterForTableView()
            }
            tableView?.arrivedZeroOffset = true
        }else {
            tableView?.arrivedZeroOffset = false
        }
        
        let basePoint = CGPoint(x: config.contentFrame.width/2.0, y: scrollView.contentOffset.y + config.contentFrame.height/2.0)
        let majorIndexPath = tableView?.indexPathForRow(at: basePoint)
        
        if majorIndexPath!.row > tableView!.cellIndex { // 向后翻页
            
            prePageStartLocation = -1
            tableView?.cellIndex = majorIndexPath!.row
            currentPageIndex = (self.tableView?.dataArray[tableView!.cellIndex].pageIndex)!
            print("进入下一页 页码 \(currentPageIndex)")
            
            if currentPageIndex == 0 {
                print("跳入下一章，从 \(currentChapterIndex) 到 \(currentChapterIndex + 1)")
                updateChapterIndex(index: currentChapterIndex + 1)
                self.statusBarForTableView?.totalPageCounts = self.pageArrayFromCache(chapterIndex: currentChapterIndex).count
            }
            self.statusBarForTableView?.curPageIndex = currentPageIndex
            
            // 到达本章节最后一页，请求下一章
            if tableView?.cellIndex == (self.tableView?.dataArray.count)! - 1 {
                self.requestNextChapterForTableView()
            }
            
            if self.delegate?.reader(reader: readerProgressUpdated: curPage: totalPages: ) != nil {
                self.delegate?.reader(reader: self, readerProgressUpdated: currentChapterIndex, curPage: currentPageIndex + 1, totalPages: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count)
            }
        }else if majorIndexPath!.row < tableView!.cellIndex {     //向前翻页
            prePageStartLocation = -1
            tableView?.cellIndex = majorIndexPath!.row
            currentPageIndex = (self.tableView?.dataArray[tableView!.cellIndex].pageIndex)!
            print("进入上一页 页码 \(currentPageIndex)")
            
            let previousPageIndex = self.tableView!.dataArray[tableView!.cellIndex + 1].pageIndex
            if currentChapterIndex - 1 > 0 && currentPageIndex == self.pageArrayFromCache(chapterIndex: currentChapterIndex - 1).count - 1 && previousPageIndex == 0 {
                print("跳入上一章，从 \(currentChapterIndex) 到 \(currentChapterIndex - 1)")
                updateChapterIndex(index: currentChapterIndex - 1)
                self.statusBarForTableView?.totalPageCounts = self.pageArrayFromCache(chapterIndex: currentChapterIndex).count

            }
            self.statusBarForTableView?.curPageIndex = currentPageIndex
            
            if self.delegate?.reader(reader: readerProgressUpdated: curPage: totalPages: ) != nil {
                self.delegate?.reader(reader: self, readerProgressUpdated: currentChapterIndex, curPage: currentPageIndex + 1, totalPages: self.pageArrayFromCache(chapterIndex: currentChapterIndex).count)
            }
        }
    }
    
    

}
