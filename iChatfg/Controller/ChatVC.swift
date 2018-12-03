//
//  ChatVC.swift
//  iChatfg
//
//  Created by 67621177 on 30/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore

class ChatVC: JSQMessagesViewController {
    // Configure library necessary variables
    var outGoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    //fixes for iphone 10
    
    override func viewDidLayoutSubviews() {
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
     //end fixes
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()?.firstname
        
        //fix large title
        navigationItem.largeTitleDisplayMode = .never
        //csutom back button
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backButtonPressed))]
        
        //set avatar sizes to zero. Colllection view is part of the library
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        //fixes for iphone 10
        
        //that selector is defined on JSQMessagesViewController library
        let constraints = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        
        //set priority
        constraints.priority = UILayoutPriority(rawValue: 1000)
        
        //defined on library
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        //end fixes
        
        //custom send button. Micro if there is no message to be sent
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
        
    }
    //MARK: - JSQmessages delegate functions
    //Change button icon depending on text on the input
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != ""{
            self.updateSendButton(isSend: true)
        }else{
            self.updateSendButton(isSend: false)
        }
    }
    
    
    //accessory button pressed
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("Acessory btn pressed!!")
        //display menu when clicking accessory btn
        
        //crete menu alert
        let menuOptions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //create our actions for menu
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("Camera pressed!!")
        }
        
        let sharePicture = UIAlertAction(title: "Photo library", style: .default) { (action) in
            print("Photo library pressed!!")
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video Library pressed!!")
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share Location pressed!!")
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel pressed!!")
        }
        //set images to actions
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePicture.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        //add actions to controller
        menuOptions.addAction(takePhotoOrVideo)
        menuOptions.addAction(sharePicture)
        menuOptions.addAction(shareVideo)
        menuOptions.addAction(shareLocation)
        menuOptions.addAction(cancel)
        
        
        //for ipad not to crash. To upload the app this is required?
        if(UI_USER_INTERFACE_IDIOM() == .pad){
            //we are running app on ipad
            if let currentPopoverpresentationcontroller = menuOptions.popoverPresentationController {
                currentPopoverpresentationcontroller.sourceView  = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentationcontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentationcontroller.permittedArrowDirections = .up
                 self.present(menuOptions, animated: true, completion: nil)
            }
            
        }else{
            //iphone
            //present menu
            self.present(menuOptions, animated: true, completion: nil)
        }
        
       
        
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("Send button pressed!!")
        //distiguish between mic and send
        //Reset button to micro when clicking send
        if text != ""{
            print("Send message pressed!!")
            self.sendMessage(text: text, date: date, picture: nil, video: nil, audio: nil)
            self.updateSendButton(isSend: false)
        }else{
           print("Micro pressed!!")
        }
    }
    
    
    
    //MARK: - Ibactions
    @objc func backButtonPressed(){
        print("Back button pressed")
    }
    
    func updateSendButton(isSend:Bool){
        //update image
        if isSend{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        }else{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }
    
    //MARK: Send function. It'll tak care of any kind of message
    func sendMessage(text:String?,date: Date?,picture:UIImage?, video: NSURL?, audio:String? ){
        guard let text = text, text != "" else { return }
        print("Text to send",text)
        
    }

}
