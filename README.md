# DUAReader
电子书阅读器，支持txt，epub（图文混排），纯swift编写，自动提取章节，支持翻页模式切换，更改背景，字体字号，章节跳转等各种常用功能

An e-book reader, supporting txt, epub, written in swift, has a variety of commonly used features, including automatic extraction of chapters, page turning mode switching, changing the background, font size, chapter jump, etc.

![image](https://github.com/nothot/DUAReader/blob/master/reader.gif)

# 20180721 Updated
DUAReader现全面支持Objective-C，兼容Objective-C的版本将在fitOC分支单独维护，获取方式：

DUAReader now fully supports Objective-C, and the Objective-C compatible version will be maintained separately in the fitOC branch

- 克隆代码到本地

git clone https://github.com/nothot/DUAReader.git

- 切换到fitOC分支

git checkout -b fitOC origin/fitOC

# Example
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
        // epub示例
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

See demo for more details

可以引入源码或编译为framework进行使用，注意工程需要添加libxml2动态库依赖，可参看demo工程（epub解析需要）

**说明**
项目中引入了三个第三方framework是由objective-C编写，项目本身为swift编写
