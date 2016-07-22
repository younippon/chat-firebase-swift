//
//  SessionHelper.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/22.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import Foundation
import Firebase

class SessionHelper {
    
    static func getCurrentUser() -> FIRUser? {
        return FIRAuth.auth()?.currentUser
    }
    
}