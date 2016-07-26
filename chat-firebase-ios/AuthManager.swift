//
//  AuthManager.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/24.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import Foundation
import Firebase

class AuthManager {
    
    static let sharedManager = AuthManager()
    private init() {
    }
    
    var rootRef: FIRDatabaseReference!
    var roomId: String?
    var auth: FIRUser?
    var name: String?
    
    var findRoomHandle: FIRDatabaseHandle?
    var findUserHandle: FIRDatabaseHandle?
    
    
    let userPath = "users"
    let roomPath = "rooms"
    
    func getMessagePath() -> String {
        return "rooms/\(roomId!)/messages"
    }
    
    //ログイン処理
    func login(username: String, withBlock block: (FIRUser?) -> Void) {
        rootRef = FIRDatabase.database().reference()
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            if error != nil {
                block(nil)
                return
            }
            self.auth = user
            self.name = username
            block(user)
        }
    }
    
    //ログインユーザの作成
    func registUser(uid: String) {
        let userRef = rootRef.child(userPath)
        let user = ["name": name!,
                    "inRoom": false]
        userRef.child(uid).setValue(user)
    }
    
    func updateUser(isInRoom: Bool) {
        let userRef = rootRef.child(userPath)
        userRef.child((self.auth?.uid)!).updateChildValues(["inRoom": isInRoom])
    }
    
    //非チャットユーザを監視
    func findUser(withBlock block: (String, String) -> Void) {
        let ref = rootRef.child(userPath)
        findUserHandle = ref.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            
            let uid = snapshot.key
            let name = snapshot.value!["name"] as! String
            let isInRoom = snapshot.value!["inRoom"] as? Bool
            
            if !isInRoom! && uid != self.auth?.uid {
                block(uid, name)
            }
        })
    }
    
    //ルームの作成
    func addRoomWithUserId(outcomingUid: String) {
        let roomRef = self.rootRef.child(roomPath).childByAutoId()
        let room = ["user": [(self.auth?.uid)! as String, outcomingUid]]
        roomRef.setValue(room)
    }
    
    //ルームの監視
    func findRoom(withBlock block: (String, String) -> Void) {
        let ref = FIRDatabase.database().reference().child(roomPath)
        findRoomHandle = ref.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            var users = snapshot.value!["user"] as! Array<String>
            
            //自分を含むルームが存在する時
            if let index = users.indexOf((self.auth?.uid)!) {
                self.roomId = snapshot.key
                users.removeAtIndex(index)
                self.updateUser(true)
                block(users[0], self.name!)
                return
            }
        })
    }
    
    //チャットの開始
    func setupFirebase(withBlock block: (String, String, String) -> Void) {
        let roomRef = rootRef.child(getMessagePath())
        removeObserveEvents()
        
        roomRef.queryLimitedToLast(100).observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            let text = snapshot.value!["text"] as! String
            let sender = snapshot.value!["from"] as! String
            let name = snapshot.value!["name"] as! String
            block(sender, name, text)
        })
    }
    
    //監視の削除
    func removeObserveEvents() {
        let roomRef = rootRef.child(roomPath)
        roomRef.removeObserverWithHandle(findRoomHandle!)
        
        let userRef = roomRef.child(userPath)
        userRef.removeObserverWithHandle(findUserHandle!)
    }
    
    //メッセージの送信
    func postMessage(senderId: String, senderDisplayName: String, text: String) {
        let postRef = rootRef.child(getMessagePath())
        let post = ["from": senderId,
                    "name": senderDisplayName,
                    "text": text]
        postRef.childByAutoId().setValue(post)
    }
}