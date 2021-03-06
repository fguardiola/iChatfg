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

class ChatVC: JSQMessagesViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    //variables pass from previous view controller
    var chatRoomId : String!
    var chatMembers : [String]!
    var memebersToPush : [String]!
    var titleName: String!
    var legitTypes = [kTEXT,kVIDEO,kPICTURE,kLOCATION]
    var maxMessagesNumber = 0
    var minMessagesNumber = 0
    var loadOld = false
    //count the messages loaded from FB
    var loadedMessagesCount = 0
    var isGroup : Bool?
    var group: NSDictionary?
    var withUsers : [FUser] = []
    
    var messages : [JSQMessage] = []
    var messagesDictionaryArray : [NSDictionary] = []
    var loadedMessages :  [NSDictionary] = []
    //have the images separate to be able to see them all toguether
    var picturesMessages: [NSDictionary] = []
    
    var intialLoadCompleted = false;
    
    //listeners
    // other user is typing
    var typingListener : ListenerRegistration?
    //other user has read a message
     var statusChangeListener : ListenerRegistration?
    //new message
     var newMessageListener : ListenerRegistration?
    
    // Configure library necessary variables
    var outGoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    //MARK:- Custom header
    //view
    var leftBarView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 45))
        return view
    }()
    //avatar
    var avatarButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    //title & subtitle
    var titleLbl: UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        return title
    }()
    var subtTitleLbl: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitle.textAlignment = .left
        subTitle.font = UIFont(name: subTitle.font.fontName, size: 10)
        return subTitle
    }()
    
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
        //temp
        self.isGroup = false
        self.setUI()
        
        
        //set avatar sizes to zero. Colllection view is part of the library
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        self.loadMessages()
        
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
    //MARK: - JSQmessages datasource functions
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        //change style depending on incng outgoing message
        
        let data4Cell = messages[indexPath.row]
        
        if FUser.currentId() == data4Cell.senderId {
            //outgoing
            cell.textView?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }else {
            cell.textView?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        return cell
    }
    //desplay message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return messages.count
    }
    //configure bubble around text
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if FUser.currentId() == data.senderId {
            //outgoing
            return outGoingBubble
        }
        return incomingBubble
        
    }
    //display tistamps avery 3 cells
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        
        if indexPath.item % 3 == 0{
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        return nil
    }
    //set high for top label to be able to see the tim stamp
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0{
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }
    //botom label
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        //we are going to display status for mssages delivered & read
        //get message status. we have this info on message dictionary version
        let message = messagesDictionaryArray[indexPath.row]
        
        let status : NSAttributedString //we have to return that
        let attributedStringColor  = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)]
        
        switch message[kSTATUS] as! String{
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read" + " " + self.readTimeFrom(dateString: message[kREADDATE] as! String)
             status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        default:
            status = NSAttributedString(string: "✔︎")
        }
        //if its the last one
        if indexPath.row == messages.count - 1{
            return status
        }else {
            return NSAttributedString(string: "")
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        //we want to see status of messages sent by the user
        if data.senderId == FUser.currentId(){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }else{
            return 0.0
        }
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
        
        let camera = Camera(delegate_: self)
        //display menu when clicking accessory btn
        
        //crete menu alert
        let menuOptions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //create our actions for menu
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("Camera pressed!!")
            camera.PresentMultyCamera(target: self, canEdit: false)
        }
        
        let sharePicture = UIAlertAction(title: "Photo library", style: .default) { (action) in
            print("Photo library pressed!!")
             camera.PresentPhotoLibrary(target: self, canEdit: false)
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video Library pressed!!")
            camera.PresentVideoLibrary(target: self, canEdit: false)
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minMessagesNumber)
        collectionView.reloadData()
        print("Load more messages....")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("Tap on meesage at \(indexPath.row)")
        //get message
        let messageDictionary = messagesDictionaryArray[indexPath.row]
        //type of message
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kPICTURE:
            print("Picture message tapped")
            //load image browser
            let message = messages[indexPath.row]
            let mediItem = message.media as! JSQPhotoMediaItem
            
            let photos = IDMPhoto.photos(withImages: [mediItem.image])
            let photoBowser = IDMPhotoBrowser(photos: photos)
            //present photobrowser with the tapped picture
            self.present(photoBowser!, animated: true, completion: nil)
            
        case kLOCATION:
            print("Location message tapped")
        case kVIDEO:
            print("Video message tapped")
            //we want to load player and play video
            //get JQSMessage
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! VideoMessage
            //Media player
            let player = AVPlayer(url: mediaItem.fileUrl! as URL )
            //Video controller
            let moviePlayerVC = AVPlayerViewController()
            //session Audio
            let audioSession = AVAudioSession.sharedInstance()
            //configure audio
            try! audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            
            moviePlayerVC.player = player
            
            //present video view controller
            self.present(moviePlayerVC, animated: true) {
                moviePlayerVC.player!.play()
            }
            
        default:
            print("Unknown message tapped")
        }
    }
    
    //MARK:- Load messages
    func loadMessages(){
        //last 11 messages and load rest in background
        
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                self.intialLoadCompleted = true
                //listen for new chats
                return
                
            }
            
//            if !snapshot.isEmpty {
//                dictionaryFromSnapshots(snapshots: snapshot.documents)
//            }
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            
            //get rid of corrupted entries
            self.loadedMessages = self.removeBadMessages(allmessages: sorted)
            //insert messages
            self.insertMessages()
            print("We have \(self.messages.count) messages loaded")
            //scroll to last message
            self.finishReceivingMessage()
            
            self.intialLoadCompleted = true
            
            /****************************TODOs**********************************/
            //get picture messages
            
            //get old messages in the background
            self.loadOldMessages()
            
            //listen for new messages
            self.listenForNewMessages()
            
        }
    }
    func listenForNewMessages(){
        //we have to update messages sent after the last message loaded date
        var lastMessageLoadedDate = "0"
        
        if loadedMessages.count > 0 {
            lastMessageLoadedDate = loadedMessages.last![kDATE] as! String
        }
        
        //add a listener to this specific chat room
        self.newMessageListener = reference(.Message).document(FUser.currentId()).collection(self.chatRoomId).whereField(kDATE, isGreaterThan: lastMessageLoadedDate).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            //check if snaphot != empty
            if !snapshot.isEmpty{
                //check validity of messages
                for diff in snapshot.documentChanges{
                    //here we are going to get all updates on DB added,updated...
                    //check change
                    if diff.type == .added {
                        //we have a new message
                        let newMessage = diff.document.data() as NSDictionary
                        //check validity of new message
                        if let type = newMessage[kTYPE]{
                            //check type is valid
                            if self.legitTypes.contains(newMessage[kTYPE] as! String){
                                if type as! String == kPICTURE{
                                    //update picture array
                                }
                                //add new message to array for displaying
                                if (self.insertInitialLoadMessages(messageDictionary: newMessage)){
                                    //incoming message sound
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
            
            
        })
    }
    //MARK:- Load old messages in te background
    func loadOldMessages(){
        //get date of first message shown. Ge are getting the last 11 on load. If there are more, load them in backgorund and store them in orther before the oes we have loaded (last eleven)
        guard let firstMesageDate = loadedMessages.first?[kDATE] else { return }
        
        //get older messages from FB
        reference(.Message).document(FUser.currentId()).collection(self.chatRoomId).whereField(kDATE, isLessThan: firstMesageDate as! String).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            
            if !snapshot.isEmpty{
                //convert JSON to dictionaries and sort the result
                
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                //filter bad messages and store them on loadedMessages before he existiing ones
                self.loadedMessages = self.removeBadMessages(allmessages: sorted) + self.loadedMessages
                
                //we'd have to prepare pictures here
                
                //update min and max vars. Dont get these values
                self.maxMessagesNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
            }
        }
        
        
        
    }
    
    //MARK:- Insert Messages. Create JQSMessages from our FB messages
    func insertMessages(){
//        print("LoadedMessages",loadedMessages.count,"loadedMessagesCount",loadedMessagesCount)
        self.maxMessagesNumber = loadedMessages.count - self.loadedMessagesCount
        self.minMessagesNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES//messages to display
        
        //order messages
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
//        print("Min",minMessagesNumber,"Max",maxMessagesNumber)
        for i in minMessagesNumber ..< maxMessagesNumber{
            let messageLoaded = loadedMessages[i]
//
            //insert message in our JSQ array
            loadedMessagesCount += 1
            self.insertInitialLoadMessages(messageDictionary: messageLoaded)
            //JQS property. If we have mre messages than the ones we habe shown
            self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
           
        }
    }
    
    func insertInitialLoadMessages(messageDictionary:NSDictionary) -> Bool{
        //Incoming messge instance init with JQS collection view
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
        //check if message is incoming or outgoing
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId(){
            //incoming message update message status to be seeing as read by the other user
            
        }
        //create JQS message and add it to arrays
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: self.chatRoomId)
        
        if message != nil{
            //append to tracking arrays. Sync both arrays
            self.messages.append(message!)
            self.messagesDictionaryArray.append(messageDictionary)
        }
        
        //we are going to return if message is incoming(other user) or outgoing (this user)
        return self.isIncoming(messageDictionary: messageDictionary)
        
    }
    //Mark: - Load more messages
    
    func loadMoreMessages(maxNumber: Int, minNumber:Int){
        
        if loadOld{
            maxMessagesNumber = minNumber - 1
            minMessagesNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        
        if minMessagesNumber < 0 {
            minMessagesNumber = 0
        }
        print((minMessagesNumber ... maxMessagesNumber).reversed())
        for i in (minMessagesNumber ... maxMessagesNumber).reversed(){
            let messageDictionary = loadedMessages[i]
            if insertMessage(messageDictionary: messageDictionary) {
               loadedMessagesCount += 1
            }
        }
        loadOld = true
        self.showLoadEarlierMessagesHeader = loadedMessages.count != loadedMessagesCount
    }
    
    func insertMessage(messageDictionary: NSDictionary) -> Bool{
        //insert messages on collection at index zero
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
        
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: self.chatRoomId)
        if message != nil {
            self.messages.insert(message!, at: 0)
            self.messagesDictionaryArray.insert(messageDictionary, at: 0)
            return true
        }
        return false
    }
    //MARK: - Ibactions
    @objc func backButtonPressed(){
        print("Back button pressed")
        navigationController?.popViewController(animated: true)
    }
    @objc func infoButtonPressed(){
        print("Info button pressed")
    }
    
    @objc func groupIconPressed(){
        print("Group Icon Pressed!!")
    }
    @objc func userIconPressed(){
        //navigate to user profile
          print("User Icon Pressed!!")
        let profileVC = UIStoryboard.init(name:"Main",bundle:nil).instantiateViewController(withIdentifier: "userProfile") as! ProfileTVC
             profileVC.user = self.withUsers.first
        
        navigationController?.pushViewController(profileVC, animated: true)
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
    func sendMessage(text:String?,date: Date,picture:UIImage?, video: NSURL?, audio:String? ){
        var outgoingMessage : OutgoingMessage?
        let currentUser = FUser.currentUser()!
        //Here we can have any kinfd of message
        
        //Text message
        if let text = text {
            //message is not nil
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
            
        }
        //Picture message
        if let pic = picture{
            uploadImage(image: pic, chatRoomId: self.chatRoomId, view: self.navigationController!.view) { (imageLink) in
                if imageLink != nil {
                    
                    //to display on chatsVC as last message sent
                    let text = "[\(kPICTURE)]" 
                    outgoingMessage = OutgoingMessage(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kPICTURE)
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    //we have here any kind of message
                    outgoingMessage?.sendMessage(chatRomId: self.chatRoomId, messageDictionary:outgoingMessage!.messageDctionary , memebersIds: self.chatMembers, memebersToPush: self.memebersToPush)
                    
                }else{
                    return
                }
            }
            return
        }
        
        //Send video
        if let video = video {
            let videoData = NSData(contentsOfFile: video.path!)
            
            let thumbnailData = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            
            uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
                if videoLink != nil{
                    let text = "[\(kVIDEO)]"
                    outgoingMessage = OutgoingMessage(message: text, video: videoLink!, thumbnail: thumbnailData! as NSData, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kVIDEO)
                    
                    
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    //we have here any kind of message
                    outgoingMessage?.sendMessage(chatRomId: self.chatRoomId, messageDictionary:outgoingMessage!.messageDctionary , memebersIds: self.chatMembers, memebersToPush: self.memebersToPush)
                    
                }
            }
            return
            
        }
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        //we have here any kind of message
        outgoingMessage?.sendMessage(chatRomId: self.chatRoomId, messageDictionary:outgoingMessage!.messageDctionary , memebersIds: self.chatMembers, memebersToPush: self.memebersToPush)
    }
    
    //MARK: - Helper functions
    
    func removeBadMessages (allmessages: [NSDictionary]) -> [NSDictionary]{
        var tempMessages = allmessages
        
        for message in tempMessages {
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String){
                    tempMessages.remove(at: tempMessages.index(of: message)!)
                }
                
            }else{
                tempMessages.remove(at: tempMessages.index(of: message)!)
            }
        }
        return tempMessages
    }
    
    func isIncoming(messageDictionary:NSDictionary) -> Bool{
        print("IsIncoming",messageDictionary[kSENDERID] as! String == FUser.currentId())
        return messageDictionary[kSENDERID] as! String != FUser.currentId()
    }
    //MARK:- UIImagePickerController delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //function invoked when you click on picture/video
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        sendMessage(text: nil, date: Date(), picture: picture, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    //display tim in HH:mm
    func readTimeFrom(dateString:String) ->String{
        let date = dateFormatter().date(from: dateString)
        
        let newDateFormat = dateFormatter()
        newDateFormat.dateFormat = "HH:mm"
        
        return newDateFormat.string(from: date!)
        
    }
    
    func setUI(){
        
        leftBarView.addSubview(self.avatarButton)
        leftBarView.addSubview(self.titleLbl)
        leftBarView.addSubview(self.subtTitleLbl)
        
        //Create right info button
        let inFoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        //Add to navbar
        navigationItem.rightBarButtonItem = inFoButton
        let leftBarButton = UIBarButtonItem(customView: leftBarView)
        //add target to button depending on is group or not
        if self.isGroup!{
            self.avatarButton.addTarget(self, action: #selector(self.groupIconPressed), for: .touchUpInside)
        }else{
            self.avatarButton.addTarget(self, action: #selector(self.userIconPressed), for: .touchUpInside)
        }
        
        navigationItem.leftBarButtonItems?.append(leftBarButton)
        
        getUsersFromFirestore(withIds: chatMembers) { (users) in
            self.withUsers = users
            //update leftbarbutton
            if !self.isGroup!{
                //update user info
                self.setUserInfo(user: self.withUsers.first!)
            }
        }
        
        //
        
        
    }
    func setUserInfo(user:FUser){
        titleLbl.text = user.fullname
        subtTitleLbl.text = user.isOnline ? "Online": "Offline"
        imageFromData(pictureData: user.avatar) { (image) in
            if (image != nil) {
                self.avatarButton.setImage(image?.circleMasked, for: .normal)
            }
        }
    }
}
