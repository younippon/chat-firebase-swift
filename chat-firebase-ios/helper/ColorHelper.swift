//
//  ColorHelper.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/22.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import UIKit

class ColorHelper {
    
    static let DENO: CGFloat = 255.0
    
    static func colorBase() -> UIColor {
        return UIColor.init(red: 250.0 / DENO, green: 250.0 / DENO, blue: 250.0 / DENO, alpha: 1.0)
    }
    
    static func colorMain() -> UIColor {
        return UIColor.init(red: 238.0 / DENO, green: 238.0 / DENO, blue: 238.0 / DENO, alpha: 1.0)
    }
    
    static func colorAccent() -> UIColor {
        return UIColor.init(red: 66.0 / DENO, green: 66.0 / DENO, blue: 66.0 / DENO, alpha: 1.0)
    }
    
    static func colorText() -> UIColor {
        return UIColor.init(red: 66.0 / DENO, green: 66.0 / DENO, blue: 66.0 / DENO, alpha: 1.0)
    }
    
}