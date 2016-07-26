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
    
    var manager = AuthManager.sharedManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChatUi()
        self.messages = []
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        sendAutoMessage("こんにちは！お名前を教えてください。", senderId: "", displayName: "")
    }
    
    func didInqutUserInfo(username: String) {
        manager.login(username, withBlock: { (user) in
            if user == nil {
                self.onLoginError(username)
                return
            }
            self.onLoginSuccess(user!, username: username)
        })
    }
    
    func onLoginSuccess(user: FIRUser, username: String) {
        self.setupUser(user.uid, name: username)
        self.sendAutoMessage("\(username)さんのログインが完了しました！", senderId: "", displayName: "")
        
        manager.registUser(user.uid)
        
        sendAutoMessage("お声がかかったら、話してみたい人をタップしましょう！", senderId: "", displayName: "")
        manager.findRoom(withBlock: { (outgoingId, name) in
            self.didFindOutgoing(outgoingId, name: "相手")
        })
        manager.findUser(withBlock: { (userId, name) in
            
            self.sendAutoMessage("\(name)", senderId: userId, displayName: "")
        })
    }
    
    func onLoginError(name: String) {
        self.sendAutoMessage("\(name)さんのログインに失敗しました…。", senderId: "", displayName: "")
        self.sendAutoMessage("もう一度名前を教えてください。", senderId: "", displayName: "")
    }
    
    func didFindOutgoing(outgoingId: String, name: String) {
        sendAutoMessage("\(name)さんが入室しました！", senderId: "", displayName: "")
        sendAutoMessage("それでは楽しい時間をお過ごしください♩", senderId: "", displayName: "")
        
        manager.setupFirebase(withBlock: { (sender, name, text) in
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
    
        if manager.auth == nil {
            if !isVariableUsername(text) {
                sendAutoMessage("\(text)は名前として利用できません…。", senderId: "", displayName: "")
                sendAutoMessage("他の名前でもう一度お願いします。", senderId: "", displayName: "")
                return
            }
            didInqutUserInfo(text)
            return
        }
        
        self.finishSendingMessageAnimated(true)
        manager.postMessage(senderId, senderDisplayName: senderDisplayName, text: text)
    }
    
    func isVariableUsername(name: String) -> Bool {
        return name.characters.count < 16
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
    
    //アバターをタップした時
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView, atIndexPath indexPath: NSIndexPath) {
        
        let message = self.messages?[indexPath.item]
        if message?.senderId == self.senderId || message?.senderId == "" {
            return
        }
        manager.addRoomWithUserId((message?.senderId)!)
    }
    
    //自動返信
    func sendAutoMessage(messageStr: String, senderId: String, displayName: String) {
        let message = JSQMessage(senderId: senderId, displayName: displayName, text: messageStr)
        self.messages?.append(message)
        self.finishReceivingMessageAnimated(true)
    }
}