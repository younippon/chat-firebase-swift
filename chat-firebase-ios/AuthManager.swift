//
//  AuthManager.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/24.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import Foundation
import Firebase

protocol AuthDelegate {
    func onLoginSuccess(user: FIRUser?, name: String)
    func onLoginError(error: NSError, name: String)
    
    func didFindUserWaiting(uid: String, name: String)
    func didFindRoomEntering(uid: String, name: String)
    
    func didFindNewMessage(fromId: String, name: String, text: String)
    
    func didPartnerLeave(name: String)
}

class AuthManager {
    
    static let sharedManager = AuthManager()
    private init() {
    }
    
    private var rootRef: FIRDatabaseReference!
    private var roomId: String?
    private var auth: FIRUser?
    private var name: String?
    
    private var roomHandle: FIRDatabaseHandle?
    private var userHandle: FIRDatabaseHandle?
    private var messageHandle: FIRDatabaseHandle?
    
    private let userPath = "users"
    private let roomPath = "rooms"
    
    var delegate: AuthDelegate?
    
    private func getMessagePath() -> String {
        return "rooms/\(roomId!)/messages"
    }
    
    func isLogin() -> Bool {
        return auth != nil
    }
    
    func isInRoom() -> Bool {
        return roomId != nil
    }
    
    func login(username: String) {
        rootRef = FIRDatabase.database().reference()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AuthManager.willFinishApp), name: UIApplicationWillTerminateNotification, object: nil)
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            if error != nil {
                self.delegate?.onLoginError(error!, name: username)
                return
            }
            self.auth = user
            self.name = username
            self.delegate?.onLoginSuccess(user, name: username)
        }
    }
    
    private func setupUserInfo(user: String, username: String) {
        
    }
    
    func registUser(uid: String) {
        let userRef = rootRef.child(userPath)
        let user = ["name": name!,
                    "inRoom": false,
                    "isActive": true]
        userRef.child(uid).setValue(user)
    }
    
    private func updateUserParamBool(flag: Bool, param: String) {
        let userRef = rootRef.child(userPath)
        userRef.child((self.auth?.uid)!).updateChildValues([param: flag])
    }
    
    func addMonitoringUsers() {
        let ref = rootRef.child(userPath)
        userHandle = ref.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            self.checkUserIfWaiting(snapshot)
        })
    }
    
    private func checkUserIfWaiting(snapshot: FIRDataSnapshot) {
        let uid = snapshot.key
        let name = snapshot.value!["name"] as! String
        let isInRoom = snapshot.value!["inRoom"] as? Bool
        
        if !isInRoom! && uid != self.auth?.uid {
            self.delegate?.didFindUserWaiting(uid, name: name)
        }
    }
    
    func createRoom(outgoingUid: String) {
        let roomRef = self.rootRef.child(roomPath).childByAutoId()
        let room = ["user": [(self.auth?.uid)! as String, outgoingUid],
                    "isActive": true]
        roomRef.setValue(room)
    }
    
    func addMonitoringRooms() {
        let ref = FIRDatabase.database().reference().child(roomPath)
        roomHandle = ref.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            self.checkRoomIfEntering(snapshot)
        })
    }
    
    private func checkRoomIfEntering(snapshot: FIRDataSnapshot) {
        let isActive = snapshot.value!["isActive"] as! Bool
        if !isActive {
            return
        }
        
        var users = snapshot.value!["user"] as! Array<String>
        if let index = users.indexOf((self.auth?.uid)!) {
            self.roomId = snapshot.key
            users.removeAtIndex(index)
            self.updateUserParamBool(true, param: "inRoom")
            delegate?.didFindRoomEntering(users[0], name: self.name!)
        }
    }
    
    private func updateRoomIsActive(isActive: Bool) {
        let roomRef = rootRef.child(roomPath)
        roomRef.child(roomId!).updateChildValues(["isActive": isActive])
    }
    
    func addMonitorignMessages() {
        let roomRef = rootRef.child(getMessagePath())
        messageHandle = roomRef.queryLimitedToLast(100).observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            
            let fromId = snapshot.value!["from"] as! String
            let name = snapshot.value!["name"] as! String
            let text = snapshot.value!["text"] as! String
            
            self.delegate?.didFindNewMessage(fromId, name: name, text: text)
        })
    }
    
    func addMonitoringPartner(uid: String) {
        let ref = rootRef.child(userPath)
        userHandle = ref.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            
            let checkId = snapshot.key
            if checkId == uid {
                
                let isActive = snapshot.value!["isActive"] as? Bool
                self.checkPartnerIfLeaving(isActive!)
            }
        })
    }
    
    private func checkPartnerIfLeaving(isActive: Bool) {
        if !isActive {
            self.delegate?.didPartnerLeave("相手")
        }
    }
    
    func removeMonitoringAll() {
        if let handle = roomHandle {
            removeMonitoring(roomPath, handle: handle)
        }
        
        if let handle = userHandle {
            removeMonitoring(userPath, handle: handle)
        }
        
        if let handle = messageHandle {
            removeMonitoring(getMessagePath(), handle: handle)
        }
    }
    
    func removeMonitoring(path: String, handle: FIRDatabaseHandle) {
        let ref = rootRef.child(path)
        ref.removeObserverWithHandle(handle)
    }
    
    func postMessage(fromId: String, name: String, text: String) {
        let postRef = rootRef.child(getMessagePath())
        let post = ["from": fromId,
                    "name": name,
                    "text": text]
        postRef.childByAutoId().setValue(post)
    }
    
    @objc
    func willFinishApp() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("終了します。")
        exitRoom()
    }
    
    func exitRoom() {
        updateUserParamBool(false, param: "inRoom")
        updateUserParamBool(false, param: "isActive")
    }

}