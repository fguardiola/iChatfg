//
//  UserCell.swift
//  iChatfg
//
//  Created by 67621177 on 27/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
protocol UITableViewCellDelegate {
    func avatarWasTapped(indexPath:IndexPath)
}
class UserCell: UITableViewCell {
    
    var indexPath: IndexPath!
    var delegate: UITableViewCellDelegate?
    
    
    let gestureRecognizer = UITapGestureRecognizer()

    @IBOutlet weak var fullNameLbl: UILabel!
    @IBOutlet weak var avatarImg: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        // Call function when Image tapped
        avatarImg.isUserInteractionEnabled = true
        avatarImg.addGestureRecognizer(gestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func congfigureCell(fUser:FUser, indexPath:IndexPath){
        self.indexPath = indexPath
        self.fullNameLbl.text = fUser.fullname
        
        
        if fUser.avatar != ""{
            //we have to convert our image from String to UI
            self.getAvatarImg(avatar: fUser.avatar)
        }
        //set avatar if any stored
//        guard let avatar = fUser.avatar, avatar.isNotEmpty else{ return }

       
        
    }
    func getAvatarImg(avatar: String){
        imageFromData(pictureData: avatar) { (avatarUIImage) in
            if avatarUIImage != nil{
                //set the avatar image
                self.avatarImg.image = avatarUIImage!.circleMasked
            }
        }
        
    }
    
    @objc func avatarTap(){
//        print("Avatar tap at \(String(describing: indexPath))")
        delegate?.avatarWasTapped(indexPath: self.indexPath)
    }
}
