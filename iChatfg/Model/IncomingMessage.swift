//
//  IncomingMessages.swift
//  iChatfg
//
//  Created by 67621177 on 03/12/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage{
    var collectionView : JSQMessagesCollectionView
    init(collectionView_: JSQMessagesCollectionView) {
        self.collectionView = collectionView_
    }
    
    
    //we'll get JSON objects from FB. We need a function to create message dictionaries
    func createMessage(messageDictionary:NSDictionary, chatRoomId: String) -> JSQMessage?{
        
        var message : JSQMessage?
        //this functin is gonna create messages of any type. Switch the type to create proper message
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            message = self.createTextMessage(messageDictionary: messageDictionary)
            print("Create a text message!")
        case kPICTURE:
            print("Create a picture message!")
            message = self.createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO:
            print("Create a video message!")
            message = self.createViedoMessage(messageDictionary: messageDictionary)
        case kLOCATION:
            print("Create a Location message!")
        default:
            print("Uknown Message Type")
        }
        
        if message != nil {
            return message
        }
        
        return nil
      
        
    }
    func createTextMessage(messageDictionary:NSDictionary) -> JSQMessage{
        let sender = messageDictionary[kSENDERID] as! String
        let name =  messageDictionary[kSENDERNAME] as! String
        let text = messageDictionary[kMESSAGE] as! String
        
        var date : Date!
        if let created = messageDictionary[kDATE]{
            if (created as! String).count != 14 {
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        return JSQMessage(senderId: sender, senderDisplayName: name, date: date, text: text )
    }
    
    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage{
        let sender = messageDictionary[kSENDERID] as! String
        let name =  messageDictionary[kSENDERNAME] as! String
        
        var date : Date!
        if let created = messageDictionary[kDATE]{
            if (created as! String).count != 14 {
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        //instance of photo item
        let photoItem = PhotoMediaItem(image:nil)
        photoItem?.appliesMediaViewMaskAsOutgoing = self.isOutgoing(senderId: sender)
        
        //Download image
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            if image != nil{
                //create custom JQSImage to display on chat
                photoItem?.image = image!
                self.collectionView.reloadData()
            }
        }
         return JSQMessage(senderId: sender, senderDisplayName: name, date: date, media: photoItem)
    }
    
    func createViedoMessage(messageDictionary: NSDictionary) -> JSQMessage{
        let sender = messageDictionary[kSENDERID] as! String
        let name =  messageDictionary[kSENDERNAME] as! String
        
        var date : Date!
        if let created = messageDictionary[kDATE]{
            if (created as! String).count != 14 {
                date = Date()
            }else{
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        let videoUrl = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        
        //instance of video item
        let mediaItem = VideoMessage(withFileUrl: videoUrl, maskOutgoing: self.isOutgoing(senderId: sender))
        //download video
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isReadyToPlay, filename) in
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(fileName: filename))
            mediaItem.status = kSUCCESS
            mediaItem.fileUrl = url
            
            //get image for video object
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String, withBlock: { (image) in
                if image != nil{
                    mediaItem.image = image!
                    //reload collection to reflect the new image
                    self.collectionView.reloadData()
                }
            })
            self.collectionView.reloadData()
        }
        
        
        return JSQMessage(senderId: sender, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func isOutgoing(senderId: String) -> Bool{
        return senderId  == FUser.currentId()
    }
}
