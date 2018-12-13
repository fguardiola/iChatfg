//
//  OutgoingMessage.swift
//  iChatfg
//
//  Created by 67621177 on 03/12/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import Foundation

class OutgoingMessage {
    
    let messageDctionary : NSMutableDictionary
    
    //MARK:- Initializers
    
    //text message
    init(message:String, senderId: String, senderName: String, date: Date, status: String, type: String){
        //initialize dictonary with data. Kinc of crata a JSON object, alues keys
        messageDctionary = NSMutableDictionary(objects:[ message,senderId,senderName,dateFormatter().string(from: date), status,type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
        
    }
    //picture message
    init(message:String, pictureLink: String,senderId: String, senderName: String, date: Date, status: String, type: String){
        //initialize dictonary with data. Kinc of crata a JSON object, alues keys
        messageDctionary = NSMutableDictionary(objects:[ message,pictureLink,senderId,senderName,dateFormatter().string(from: date), status,type], forKeys: [kMESSAGE as NSCopying,kPICTURE as NSCopying ,kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
        
    }
    
    //video message
    init(message:String, video: String, thumbnail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String){
        //convert thumbnail data into string to store it on FB
        let thumbnailString = thumbnail.base64EncodedData(options: NSData.Base64EncodingOptions(rawValue: 0))
        //initialize dictonary with data. Kinc of crata a JSON object, alues keys
        messageDctionary = NSMutableDictionary(objects:[ message,video,thumbnailString,senderId,senderName,dateFormatter().string(from: date), status,type], forKeys: [kMESSAGE as NSCopying,kVIDEO as NSCopying ,kTHUMBNAIL as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
        
    }
    
    
    
    //MARK: - Send message function. Talk to FB. ALl type of messages
    //We are going to store messages under messages/userId/ChatroomId/message for each user on the chat
    func sendMessage(chatRomId:String, messageDictionary: NSMutableDictionary, memebersIds: [String], memebersToPush: [String]){
        //generate unique Id for message
        let messageId = UUID().uuidString
        //add key value to dictinary. Thats why we need a mutable dictionary
        messageDctionary[kMESSAGEID] = messageId
        
        //store message for each member
        for userId in memebersIds{
            reference(.Message).document(userId).collection(chatRomId).document(messageId).setData(messageDctionary as! [String: Any])
        }
        
        //update recent chat to contain last message
        
        //Perform push notfications to reflect new message in all users on the chat
    }
}
