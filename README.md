# DUAReader
电子书阅读器，支持txt，epub（图文混排），纯swift编写，自动提取章节，支持翻页模式切换，更改背景，字体字号，章节跳转等各种常用功能

![image](https://github.com/nothot/DUAReader/blob/master/reader.gif)

# 使用示例
```
        // txt示例
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        let bookPath = Bundle.main.path(forResource: "郭黄之恋", ofType: "txt")
        mreader.readWith(filePath: bookPath!, pageIndex: 1)
```
```
        mreader = DUAReader()
        let configuration = DUAConfiguration.init()
        configuration.backgroundImage = UIImage.init(named: "backImg.jpg")
        configuration.bookType = .epub // 默认TXT类型
        mreader.config = configuration
        mreader.delegate = self
        self.present(mreader, animated: true, completion: nil)
        let epubPath = Bundle.main.path(forResource: "每天懂一点好玩心理学", ofType: "epub")
        mreader.readWith(filePath: epubPath!, pageIndex: 1)
```
更多细节可参考demo

可以引入源码或编译为framework进行使用，注意工程需要添加libxml2动态库依赖，可参看demo工程（epub解析需要）
