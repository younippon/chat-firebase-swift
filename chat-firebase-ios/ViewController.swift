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

class ViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageProfile: UIImageView!
    
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    var manager = AuthManager.sharedManager
    
    var profileButton: Button?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    func initialize() {
        manager.delegate = self
        
        setupChatUi()
        setupButtons()
        
        messages = []
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sendAutoMessage("こんにちは！お名前を教えてください。")
    }
    
    func didInqutUserInfo(username: String) {
        manager.login(username)
    }
    
    func onLoginSuccess(user: FIRUser, username: String) {
        setupUser(user.uid, name: username)
        sendAutoMessage("\(username)さんのログインが完了しました！")
        
        navigationItem.rightBarButtonItem?.enabled = true
        
        manager.registUser(user.uid)
        searchUser()
    }
    
    func searchUser() {
        sendAutoMessage("お声がかかったら、話してみたい人をタップしましょう！")
        
        self.navigationItem.leftBarButtonItem?.enabled = false
        
        manager.addMonitoringRooms()
        manager.addMonitoringUsers()
    }
    
    func didFindOutgoing(outgoingId: String, name: String) {
        sendAutoMessage("\(name)さんが入室しました！")
        sendAutoMessage("それでは楽しい時間をお過ごしください♩")
        
        self.navigationItem.leftBarButtonItem?.enabled = true
        
        manager.removeMonitoringAll()
        
        manager.addMonitorignMessages()
        manager.addMonitoringPartner(outgoingId)
    }
        
    func setupUser(id: String, name: String) {
        self.senderId = id
        self.senderDisplayName = name
    }
    
    func setupChatUi() {
        inputToolbar!.contentView!.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        setupUser("", name: "あなた")
        
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        self.outgoingBubble = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    }
    
    func setupButtons() {
        profileButton = Button(frame: CGRectMake(UIScreen.mainScreen().bounds.size.width - (Button.sizeS + Button.marginH), Button.marginV, Button.sizeS, Button.sizeS))
        profileButton!.addTarget(self, action: #selector(ViewController.didTapProfile), forControlEvents:.TouchUpInside)
        profileButton!.setImage(UIImage(named: "icon_default"), forState: .Normal)
        
        let rightButton = UIBarButtonItem.init(customView: profileButton!)
        self.navigationItem.rightBarButtonItem = rightButton
        self.navigationItem.rightBarButtonItem?.enabled = false
        
        let exitButton = Button(frame: CGRectMake(Button.marginH, Button.marginV, Button.sizeS, Button.sizeS))
        exitButton.addTarget(self, action: #selector(ViewController.didTapExit), forControlEvents:.TouchUpInside)
        exitButton.setImage(UIImage(named: "icon_exit"), forState: .Normal)
        
        let leftButton = UIBarButtonItem.init(customView: exitButton)
        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.leftBarButtonItem?.enabled = false
    }
    
    @objc
    func didTapProfile() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo: [String: AnyObject]) {
        if didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] != nil {
            
            let image = didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] as? UIImage
            profileButton!.setImage(image, forState: .Normal)
            profileButton!.imageView!.layer.cornerRadius = profileButton!.frame.size.width / 2.0
            self.outgoingAvatar.avatarImage = image
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc
    func didTapExit() {
        let alert = createAlertLeaving()
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func createAlertLeaving() -> UIAlertController {
        let alert = UIAlertController(
            title:"チャットの終了",
            message: "本当にチャットを終了してもよろしいですか？",
            preferredStyle: .Alert
        )
        
        let actionOk = UIAlertAction(title: "はい", style: .Default,
                                     handler:{ (action:UIAlertAction!) -> Void in
                                        self.manager.exitRoom()
                                        self.manager.removeMonitoringAll()
                                        self.searchUser()
        })
        
        let actionCancel = UIAlertAction (title: "いいえ", style: .Cancel, handler:nil)
        
        alert.addAction(actionOk)
        alert.addAction(actionCancel)
        return alert
        
    }

    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        if !manager.isLogin() {
            checkUserNameIfValiable(text)
            return
        }
        
        if !manager.isInRoom() {
            return
        }
        
        self.finishSendingMessageAnimated(true)
        manager.postMessage(senderId, name: senderDisplayName, text: text)
    }
    
    func checkUserNameIfValiable(name: String) {
        if name.characters.count > 16 {
            sendAutoMessage("\(name)は名前として利用できません…。")
            sendAutoMessage("他の名前でもう一度お願いします。")
            return
        }
        didInqutUserInfo(name)
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
        
        if manager.isInRoom() {
            return
        }
        
        manager.createRoom((message?.senderId)!)
    }
    
    func sendAutoMessage(messageStr: String, senderId: String, displayName: String) {
        let message = JSQMessage(senderId: senderId, displayName: displayName, text: messageStr)
        self.messages?.append(message)
        self.finishReceivingMessageAnimated(true)
    }
    
    func sendAutoMessage(messageStr: String) {
        sendAutoMessage(messageStr, senderId: "", displayName: "")
    }
}

extension ViewController : AuthDelegate {
    
    func onLoginSuccess(user: FIRUser?, name: String) {
        let uid = user!.uid
        setupUser(uid, name: name)
        sendAutoMessage("\(name)さんのログインが完了しました！", senderId: "", displayName: "")
        navigationItem.rightBarButtonItem?.enabled = true
        
        manager.registUser(uid)
        searchUser()
    }
    
    func onLoginError(error: NSError, name: String) {
        self.sendAutoMessage("\(name)さんのログインに失敗しました…。")
        self.sendAutoMessage("もう一度名前を教えてください。")
    }
    
    func didFindUserWaiting(uid: String, name: String) {
        self.sendAutoMessage("\(name)", senderId: uid, displayName: "")
    }
    
    func didFindRoomEntering(uid: String, name: String) {
        didFindOutgoing(uid, name: "相手")
    }
    
    func didFindNewMessage(fromId: String, name: String, text: String) {
        let message = JSQMessage(senderId: fromId, displayName: name, text: text)
        messages?.append(message)
        finishReceivingMessage()
    }
    
    func didPartnerLeave(name: String) {
        self.sendAutoMessage("\(name)さんが退室しました。")
    }
}