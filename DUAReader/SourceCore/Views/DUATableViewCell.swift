//
//  DUATableViewCell.swift
//  DUAReader
//
//  Created by mengminduan on 2017/12/29.
//  Copyright © 2017年 nothot. All rights reserved.
//

import UIKit
import DTCoreText

class DUATableViewCell: UITableViewCell {
    
    var dtLabel: DTAttributedLabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
    
//        self.layer.borderColor = UIColor.gray.cgColor
//        self.layer.borderWidth = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configCellWith(pageModel: DUAPageModel, config: DUAConfiguration) -> Void {
        dtLabel = DTAttributedLabel.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: config.contentFrame.height))
        dtLabel.backgroundColor = UIColor.clear
        dtLabel.edgeInsets = UIEdgeInsetsMake(0, config.contentFrame.origin.x, 0, config.contentFrame.origin.x)
        self.contentView.addSubview(dtLabel)
        dtLabel.attributedString = pageModel.attributedString
        
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
