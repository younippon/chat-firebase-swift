//
//  StorageManager.swift
//  chat-firebase-ios
//
//  Created by 佐々木耀 on 2016/07/27.
//  Copyright © 2016年 佐々木耀. All rights reserved.
//

import Foundation
import Firebase

protocol StorageDelegate {
    func didUploadSuccess(name: String)
    func didUploadFailure(error: NSError)
    
    func didDownloadSuccsess(image: UIImage, isPartner: Bool)
    func didDownloadFailure(error: NSError, isPartner: Bool)
    
    func didChangeImage(image: UIImage)
}

class StorageManager {
    
    static let sharedManager = StorageManager()
    private init() {}
    
    var delegate: StorageDelegate?
    
    private var storageRef: FIRStorageReference!
    
    private var myStorageRef: FIRStorageReference!
    
    func setupRef(uid: String) {
        storageRef = FIRStorage.storage().reference()
        myStorageRef = storageRef.child("images/\(uid).png")
    }
    
    func upload(image: UIImage, name: String) {
        if let data = UIImagePNGRepresentation(image) as NSData! {
            myStorageRef.putData(data, metadata: nil) { metadata, error in
                if (error != nil) {
                    self.delegate?.didUploadFailure(error!)
                    return
                }
                self.delegate?.didUploadSuccess(name)
            }
        }
    }
    
    func download(uid: String, isPartner: Bool) {
        let ref = storageRef.child("images/\(uid).png")
        ref.dataWithMaxSize(1 * 128 * 128) { (data, error) -> Void in
            if (error != nil) {
                self.delegate?.didDownloadFailure(error!, isPartner: isPartner)
                return
            }
            let image: UIImage! = UIImage(data: data!)
            self.delegate?.didDownloadSuccsess(image, isPartner: isPartner)
        }
    }
}