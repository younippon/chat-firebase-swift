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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFirebase()
        setupChatUi()
        self.messages = []
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
    
    func setupChatUi() {
        inputToolbar!.contentView!.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        self.senderId = "user2"
        self.senderDisplayName = "user1"
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        self.outgoingBubble = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    }
    

    //メッセージの送信
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        self.finishSendingMessageAnimated(true)
        
        sendMessageToDatabase(text)
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
        return (self.messages?.count)!
    }
    
    //返信メッセージを受信する
//    func receiveAutoMessage(messageStr: String) {
//        let message = JSQMessage(senderId: "user2", displayName: "underscore", text: messageStr)
//        self.messages?.append(message)
//        self.finishReceivingMessageAnimated(true)
//    }
}