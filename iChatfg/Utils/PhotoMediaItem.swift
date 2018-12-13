//
//  PhotoMediaItem.swift
//  iChatfg
//
//  Created by 67621177 on 07/12/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import Foundation
import JSQMessagesViewController




class PhotoMediaItem: JSQPhotoMediaItem{
    //Extend class to display properly images depending on size
    override func mediaViewDisplaySize() -> CGSize {
        //return different sizes dependion on image being portrait or landscape
        let defaultWidthHeight: CGFloat = 256 //default height or width depending on portrait/landscape
        
        var thumbnailSize: CGSize = CGSize(width: defaultWidthHeight, height: defaultWidthHeight)
        
        //check if image is portrait or landscape
        
        if (self.image != nil && self.image.size.width > 0 && self.image.size.height > 0){
            //we have an image an it has a size
            let imageWidth = self.image.size.width
             let imageHeight = self.image.size.height
            
            let aspectRatio = imageWidth / imageHeight
            
            if imageWidth > imageHeight {
                //landscape
                thumbnailSize = CGSize(width: defaultWidthHeight, height: defaultWidthHeight / aspectRatio)
            }else{
                //portrait
                thumbnailSize = CGSize(width: aspectRatio * defaultWidthHeight, height: defaultWidthHeight)
            }
        }
        
        return thumbnailSize
        
    }
}
