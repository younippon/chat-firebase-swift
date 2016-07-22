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

    var firebase: Firebase!
    
    var messages: [JSQMessage]?
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var incomingAvatar: JSQMessagesAvatarImage!
    var outgoingAvatar: JSQMessagesAvatarImage!
    
    var botStr = "こんにちは！"
    var emailStr: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = SessionHelper.getCurrentUser()
        setupIncomingUser(user)
        setupChatUi()
        
        //メッセージの初期化
        self.messages = []
        
        if user == nil {
            willLogin("現在ログインしておりません。")
        } else {
            didLogin()
        }
    }
    
    /*
     * ユーザの登録/ログイン
     */
    
    //ログイン済み判定
    func setupIncomingUser(userInfo: FIRUser?) {
        if let user = userInfo {
            updateIncomingUserInfo(user)
        } else {
            self.senderId = "unknown"
            self.senderDisplayName = "新しいユーザ"
            self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        }
    }
    
    //会員登録
    func signup(textEmail: String?, textPassword: String?) {
        guard let email = textEmail else  {
            didSignUpError()
            return
        }
        guard let password = textPassword else {
            didSignUpError()
            return
        }
        
        FIRAuth.auth()?.createUserWithEmail(email, password: password, completion: { (user, error) in
            if error == nil{
                user?.sendEmailVerificationWithCompletion({ (error) in
                    if error == nil {
                        self.didLogin()
                    } else {
                        print("\(error?.localizedDescription)")
                        self.didSignUpError()
                    }
                })
            } else {
                print("\(error?.localizedDescription)")
                self.didSignUpError()
            }
        })
    }
    
    //ログイン
    func signin(textEmail: String?, textPassword: String?) {
        guard let email = textEmail else  {
            didSignInError()
            return
        }
        guard let password = textPassword else {
            didSignInError()
            return
        }
        
        FIRAuth.auth()?.signInWithEmail(email, password: password, completion: { (user, error) in
            if error == nil{
                self.didLogin()
            }else {
                //TODO: エラー処理
                print("\(error?.localizedDescription)")
                self.didSignInError()
            }
        })
    }
    
    //ログインエラー
    func didSignInError() {
        print("ログインエラー")
        willLogin("ログインに失敗しました。もう一度お願いいたします。")
    }
    
    //登録エラー
    func didSignUpError() {
        print("登録エラー")
        willLogin("登録に失敗しました。もう一度お願いいたします。")
    }
    
    //ログイン完了
    private func didLogin() {
        print("ログインの完了")
        receiveAutoMessage("ログインが完了しました！")
    }
    
    //自分の更新
    func updateIncomingUserInfo(user: FIRUser) {
        self.senderId = user.uid
        self.senderDisplayName = user.displayName
        self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
    }
    
    //相手の更新
    func updateOutComingUserInfo(user: FIRUser) {
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
    }


    func readAvatarImage(photoUrl: String) -> UIImage? {
        //TODO: get from user.photoURL
        return nil
    }
    
    func setupChatUi() {
        self.outgoingAvatar = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "icon_default")!, diameter: 64)
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        self.incomingBubble = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        self.outgoingBubble = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    }
    
    func willLogin(firstMessage: String) {
        print("Reset")
        emailStr = nil
        receiveAutoMessage(firstMessage)
        receiveAutoMessage("メールアドレスを入力してください")
    }
    
    /*
     * メッセージのやり取り
     */
    
    
    //メッセージの送信
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        
        //新しいメッセージデータを追加する
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text)
        self.messages?.append(message)
        
        //メッセジの送信処理を完了する(画面上にメッセージが表示される)
        self.finishReceivingMessageAnimated(true)
        
        if let user = SessionHelper.getCurrentUser() {
            //擬似的に自動でメッセージを受信
            self.receiveAutoMessage("やなこった！")
        } else {
            if let email = emailStr {
                signup(email, textPassword: text)
            } else {
                emailStr = text
                receiveAutoMessage("パスワードを入力してください")
            }
        }
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
    func receiveAutoMessage(messageStr: String) {
        let message = JSQMessage(senderId: "user2", displayName: "underscore", text: messageStr)
        self.messages?.append(message)
        self.finishReceivingMessageAnimated(true)
//        botStr = message
//        NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: #selector(ViewController.didFinishMessageTimer(_:)), userInfo: nil, repeats: false)
    }
    
    func didFinishMessageTimer(sender: NSTimer) {
        let message = JSQMessage(senderId: "user2", displayName: "underscore", text: botStr)
        self.messages?.append(message)
        self.finishReceivingMessageAnimated(true)
    }}

