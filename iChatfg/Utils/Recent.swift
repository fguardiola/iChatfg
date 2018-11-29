//
//  Recent.swift
//  iChatfg
//
//  Created by 67621177 on 28/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import Foundation


// FUnctions to create recent chats objects stored on FB under recents

//Return a unique chartroomId thats gonna be the same either myself wants to talk to another user or the other way
//arround. Same Id for both users
func startPrivateChat(user1:FUser, user2:FUser) -> String {
    
    let user1Id = user1.objectId
    let user2Id = user2.objectId
    
    var chatRoomId = ""
    
    let comparation = user1Id.compare(user2Id).rawValue
    
    if comparation < 0 {
        chatRoomId = user1Id + user2Id
    }else{
        chatRoomId = user2Id + user1Id
    }
    
    let members = [user1Id,user2Id]
    //create recent chats
    createRecentChat(members: members, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE, users: [user1,user2], avatarOfGroup: nil)
    
    
    return chatRoomId
    
}

//create recent chats for members. Last 2 parameters is for group chats
func createRecentChat(members:[String], chatRoomId: String, withUserUserName:String, type: String,users:[FUser]?, avatarOfGroup: String?){
    //check if there is an existing recent for members
    var tempMembers = members //var to keep only members with no recent with chatRoomId
    //1. get recents from FB with chatroomId
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }
        // we have some a snapshot but can be empty
        if !snapshot.isEmpty{
            for recent in snapshot.documents {
                let recentData = recent.data() as NSDictionary
                    //access json data
                if let recentUserId = recentData[kUSERID]{//check validity of data
                    //compare members to see if recent has been created by any of members not to add a new one
                    if tempMembers.contains(recentUserId as! String){
                        //remove member from array
                        tempMembers.remove(at: tempMembers.index(of:recentUserId as! String)!)
                    }
                }
            }
            
        }
        //here we have reminder users. We have to create recents for the reminders
        for userId in tempMembers{
            //create a recent
            createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users, avatarOfGroup: avatarOfGroup)
        }
    }
    
}

func createRecentItem(userId: String, chatRoomId: String, members: [String],withUserUserName:String, type: String,users:[FUser]?, avatarOfGroup: String? ){
    //create a document on FB
    
    let localReference = reference(.Recent).document()//create an empty recent entry we can get id
    let recentId = localReference.documentID
    
    let date = dateFormatter().string(from: Date())
    
    var newRecent : [String: Any]!
    
    if type == kPRIVATE{
        //one to one chat
        var withUser: FUser?
        
        if users != nil && users!.count > 0{
            //grab who are we going to chat with
            if userId == FUser.currentId(){
                //in users we'll have [creatorId, otherUserId]
                withUser = users!.last
            }else{
                withUser = users!.first
            }
        }
        //add data for newRecent
        newRecent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar] as [String: Any ]
        
        
        
    }else{
        //group chat
        
        if avatarOfGroup != nil{
            newRecent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUserUserName, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!] as [String: Any ]
        }
    }
    
    //save recent chat
    localReference.setData(newRecent)
    
    
    
}
