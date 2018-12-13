//
//  VideoMessage.swift
//  iChatfg
//
//  Created by 67621177 on 13/12/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class VideoMessage: JSQMediaItem {
    var image: UIImage?
    var videoImageView: UIImageView?
    //ready to play
    var status : Int?
    var fileUrl: NSURL?
    
    init(withFileUrl: NSURL, maskOutgoing: Bool) {
        super.init(maskAsOutgoing:maskOutgoing)
        fileUrl = withFileUrl
        videoImageView = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //jqs func
    override func mediaView() -> UIView! {
        if let st = status {
            //not ready to play
            if st == 1{
                return nil
            }
            
            if st == 2{
                //show video with image and playbutton icon
                //size of JQS cell
                let size = self.mediaViewDisplaySize()
                //checkif video is outgoing or not
                let outgoing = self.appliesMediaViewMaskAsOutgoing
                //create icon
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: .white)
                //create image view to display icon
                let iconView = UIImageView(image: icon)
                //give size to icon view
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                iconView.contentMode = .center
                
                let imageView = UIImageView(image: self.image!)
                //size
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                
                //add play icon to imageView
                imageView.addSubview(iconView)
                
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                //set videoImage to the created view
                self.videoImageView = imageView
                
            }
        }
        return self.videoImageView
    }
}
