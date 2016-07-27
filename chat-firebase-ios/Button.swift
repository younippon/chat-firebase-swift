//
//  Button.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/27.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import UIKit

class Button: UIButton {
    
    static let sizeS: CGFloat = 32.0
    static let marginV: CGFloat = 22.0
    static let marginH: CGFloat = 4.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, isCircle: Bool) {
        super.init(frame: frame)
        self.imageView!.layer.cornerRadius = frame.size.width / 2.0
    }
}
