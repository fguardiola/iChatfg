//
//  recentChatCell.swift
//  iChatfg
//
//  Created by 67621177 on 29/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit

protocol RecentChatCellCellDelegate {
    func avatarWasTapped(indexPath:IndexPath)
}
class RecentChatCell: UITableViewCell {

    @IBOutlet weak var avatarImgView: UIImageView!
    @IBOutlet weak var fullNameLbl: UILabel!
    @IBOutlet weak var lastMessageLbl: UILabel!
    
    @IBOutlet weak var messageCounterBackGround: UIView!
    @IBOutlet weak var messageCounterLbl: UILabel!
    
    @IBOutlet weak var dateLbl: UILabel!
    
    var indexpath: IndexPath!
    var tapGesture = UITapGestureRecognizer()
    //delegate
    var delegate: RecentChatCellCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //tap on cell
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        // Call function when Image tapped
        avatarImgView.isUserInteractionEnabled = true
        avatarImgView.addGestureRecognizer(tapGesture)
        messageCounterBackGround.layer.cornerRadius = messageCounterBackGround.frame.size.width / 2
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func avatarTap(){
        print("Avatar tapped")
        self.delegate?.avatarWasTapped(indexPath: indexpath)
    }
    
    func generateCell(recentChat: NSDictionary, indexpath:IndexPath){
        //set our var index
        self.indexpath = indexpath
        //set data we have from recent
        
        self.fullNameLbl.text = recentChat[kWITHUSERFULLNAME] as! String
        self.lastMessageLbl.text = recentChat[kLASTMESSAGE] as! String
        self.messageCounterLbl.text = "\(recentChat[kCOUNTER] as! Int)"
        
        //avatar image. We have data as string. convrt it to UIImage
        if let avatarString = recentChat[kAVATAR]{
            imageFromData(pictureData: avatarString as! String) { (image) in
                if image != nil {
                    //set image
                    self.avatarImgView.image = image?.circleMasked
                }
            }
        }
        //counter
        if let counter = recentChat[kCOUNTER]{
            if counter as! Int == 0{
                //hide message info
                self.messageCounterLbl.isHidden = true
                self.messageCounterBackGround.isHidden = true
                
            }else{
                self.messageCounterLbl.isHidden = false
                self.messageCounterBackGround.isHidden = false
                
                self.messageCounterLbl.text = "\(counter)"
            }
        }
        
        //date
        
        var date: Date!
        if let created = recentChat[kDATE] {
            //we are storing 14 digits
            if (created as! String).count != 14 {
                //convert date to DD/MM/YYYY
                date = Date()
                
            }else{
                //get a date from string
                date = dateFormatter().date(from: created as! String)
            }
        }else{
            date = Date()
        }
        
        //convert date to meessage as a minutr ago...
        
        dateLbl.text = timeElapsed(date: date)
        
        
    }

}
