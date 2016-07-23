//
//  ViewController.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/21.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ViewController: JSQMessagesViewController {
    
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    var isStateLogin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChatUi()
        
        self.messages = []
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sendAutoMessage("こんにちは！お名前を教えてください。")
    }
    
    func didInqutUserInfo(username: String) {
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            if error != nil {
                self.onLoginError(username)
                return
            }
            self.onLoginSuccess(user!, username: username)
        }
    }
    
    func onLoginSuccess(user: FIRUser, username: String) {
        self.isStateLogin = true
        self.setupFirebase()
        self.setupUser(user.uid, name: username)
        self.sendAutoMessage("\(username)さんのログインが完了しました！")
    }
    
    func onLoginError(name: String) {
        self.sendAutoMessage("\(name)さんのログインに失敗しました…。")
        self.sendAutoMessage("もう一度名前を教えてください。")
    }
    
    func setupFirebase() {
        let rootRef = FIRDatabase.database().reference()
        rootRef.queryLimitedToLast(100).observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) in
            let text = snapshot.value!["text"] as! String
            let sender = snapshot.value!["from"] as! String
            let name = snapshot.value!["name"] as! String
            print(snapshot.value!)
            let message = JSQMessage(senderId: sender, displayName: name, text: text)
            self.messages?.append(message)
            self.finishReceivingMessage()
        })
    }
    
    func setupUser(id: String, name: String) {
        self.senderId = id
        self.senderDisplayName = name
    }
    
    func setupChatUi() {
        inputToolbar!.contentView!.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        setupUser("you", name: "あなた")
        
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        self.outgoingBubble = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    }
    

    //メッセージの送信
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
    
        if !isStateLogin {
            if !isVariableUsername(text) {
                sendAutoMessage("\(text)は名前として利用できません…。")
                sendAutoMessage("他の名前でもう一度お願いします。")
                return
            }
            didInqutUserInfo(text)
            return
        }
        
        self.finishSendingMessageAnimated(true)
        sendTextToDb(text)
    }
    
    func isVariableUsername(name: String) -> Bool {
        return name.characters.count < 16
    }
    
    func sendTextToDb(text: String) {
        //firebaseにデータを送信、保存する
        let rootRef = FIRDatabase.database().reference()
        let post = ["from": senderId,
                    "name": senderDisplayName,
                    "text": text]
        let postRef = rootRef.childByAutoId()
        postRef.setValue(post)
    }
    
    //アイテムごとに参照するメッセージデータを返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages?[indexPath.item]
    }
    
    //アイテムごとのMessageBubble(背景)を返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingBubble
        }
        return self.incomingBubble
    }
    
    //アイテムごとにアバター画像を返す
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId {
            return self.outgoingAvatar
        }
        return self.incomingAvatar
    }
    
    //アイテムの総数を返す
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let posts = self.messages {
            return posts.count
        }
        return 0
    }
    
    //自動返信
    func sendAutoMessage(messageStr: String) {
        let message = JSQMessage(senderId: "qpid", displayName: "キューピッド", text: messageStr)
        self.messages?.append(message)
        self.finishReceivingMessageAnimated(true)
    }
}