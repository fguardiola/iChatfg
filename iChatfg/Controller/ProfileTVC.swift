//
//  ProfileTVC.swift
//  iChatfg
//
//  Created by 67621177 on 28/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit

class ProfileTVC: UITableViewController {
    //Outlets
    
    @IBOutlet weak var fullNameLbl: UILabel!
    @IBOutlet weak var phoneLbl: UILabel!
    
    @IBOutlet weak var avatarLbl: UIImageView!
    @IBOutlet weak var callBtnLbl: UIButton!
    @IBOutlet weak var mssageBtnLbl: UIButton!
    
    @IBOutlet weak var blokBtnLbl: UIButton!
    //Vars
    
    var user: FUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Profile"
        navigationItem.largeTitleDisplayMode = .never
        //trick to not display more items than the esntries we have. Another option style separator = none
        tableView.tableFooterView = UIView()
        self.setUI()
   
    }
    // MARK: - IBactions
    
    @IBAction func callBtnPressed(_ sender: Any) {
    }
    
    @IBAction func messageBtnPressed(_ sender: Any) {
    }
    
    @IBAction func blockBtnPressed(_ sender: Any) {
        //we have t block/unblock user locally and in FB
        var blockedUsers = FUser.currentUser()!.blockedUsers
        
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId){
            //blocked scenario. Removed fom blocked
            let index = blockedUsers.index(of:user!.objectId)
            
            blockedUsers.remove(at: index!)
        }else{
            //add to blocked users
          blockedUsers.append(user!.objectId)
        }
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : blockedUsers]) { (error) in
            if error != nil{
                debugPrint("Error updating blocked user:\(error!.localizedDescription)")
            }else{
                //update UI
                self.updateBlockStatus()
            }
        }
        
    }
    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    //Hedaer config
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //no header visible first secion
        if section == 0 {
            return 0
        }
        return 15
    }
    
    //set up UI
    func setUI(){
        if user != nil {
            fullNameLbl.text = user!.fullname
            phoneLbl.text = user!.phoneNumber
            
            updateBlockStatus()
            
            imageFromData(pictureData: user!.avatar) { (image) in
                if (image != nil){
                    self.avatarLbl.image = image!.circleMasked
                }
            }
            
        }
    }
    
    func updateBlockStatus(){
        //update UI
        if user?.objectId == FUser.currentId(){
            //if we are looking at our profile hide block user and call/message buttons
            blokBtnLbl.isHidden = true
            callBtnLbl.isHidden = true
            mssageBtnLbl.isHidden = true
        }else {
            blokBtnLbl.isHidden = false
            callBtnLbl.isHidden = false
            mssageBtnLbl.isHidden = false
            //check if user is contained on blockusers property
            
            FUser.currentUser()!.blockedUsers.contains(user!.objectId) ? blokBtnLbl.setTitle("Unblock user", for: .normal) :  blokBtnLbl.setTitle("Block User", for: .normal)
                
        }
    }
   
}
