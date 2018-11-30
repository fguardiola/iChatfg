//
//  ChatsVC.swift
//  iChatfg
//
//  Created by 67621177 on 27/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
import Firebase

class ChatsVC: UIViewController,UITableViewDelegate,UITableViewDataSource,RecentChatCellCellDelegate,UISearchResultsUpdating {

    
  
    @IBOutlet weak var tableView: UITableView!
    
    
    var recentChats:[NSDictionary] = []
    var filteredChats:[NSDictionary] = []
    var recentListener: ListenerRegistration!
    
    
    //search controller
    var searchController =  UISearchController(searchResultsController: nil)

    
    override func viewWillAppear(_ animated: Bool) {
       self.loadRecentChats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //APPLE STYLE SETTNG TITLE
        navigationController?.navigationBar.prefersLargeTitles = true
        
        
        //trick to not display more items than the esntries we have. Another option style separator = none
        tableView.tableFooterView = UIView()
        
        //we are loading on viewDidLoad and adding listener here. We want to remove listener when navgating away
        //and load recent everytime yoyu get to this view. Better to do it on willappear/disspear
        //self.loadRecentChats()
        
        
        //set a function to add custom header to view
        self.setTableViewHeader()
        
        
        //search bar set
        navigationItem.searchController = self.searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    

    @IBAction func createNewChatPressed(_ sender: Any) {
        //Navigate to userVC
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "users") as! UsersTVC
        //we want to have it on navigation stack
//         self.present(vc, animated: true, completion: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - TableView fucnctions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //number of rows depends on searching as well
        if searchController.isActive && searchController.searchBar.text != ""{
            return filteredChats.count
        }else{
            return recentChats.count;
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "recentChatCell", for: indexPath) as? RecentChatCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        
        //we have to pass a different recentChat dependino on searching
        var recentChat: NSDictionary!
        
        if (searchController.isActive && searchController.searchBar.text != ""){
            recentChat = self.filteredChats[indexPath.row]
        }else{
            recentChat = self.recentChats[indexPath.row]
        }
       
        cell.generateCell(recentChat: recentChat, indexpath: indexPath)
        
        return cell
    }
    func loadRecentChats(){
        //Set listerner
        self.recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else { return }
            //reset recent arrays
            self.recentChats = []
            
            if !snapshot.isEmpty {
                //we have some documents. We want to create an array of SORTED NSDIctinoaries by date from
                //most recent
                let sortedRecentChats = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                //we have an array of dictionaries
                for recent in sortedRecentChats{
                    //Check validity of recent entry. There gas to be a message
                    if (recent[kLASTMESSAGE] as! String != "") && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        //we have a valid recent of user with a message and valid. Attach it to array
                        self.recentChats.append(recent)
                        
                    }
                }
                
            }
            
            self.tableView.reloadData()
            
        })
        
    }
    
    func setTableViewHeader(){
        
        let tableViewWidth = self.tableView.frame.width
    
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableViewWidth, height: 45))
        
        let headerBtnView = UIView(frame: CGRect(x: 0, y: 5, width: tableViewWidth, height: 35))
        
        let headerBtn = UIButton(frame: CGRect(x: tableViewWidth - 110, y: 10, width: 100, height: 20))
        headerBtn.setTitle("New Group", for: .normal)
        headerBtn.setTitleColor(#colorLiteral(red: 0.3631127477, green: 0.4045833051, blue: 0.8775706887, alpha: 1), for: .normal)
        //action to button
        headerBtn.addTarget(self, action: #selector(self.groupBtnPressed), for: .touchUpInside)
        
        //bottom line
        let bottomLineView = UIView(frame: CGRect(x: 0, y: headerView.frame.height - 1, width: tableViewWidth, height: 1))
        bottomLineView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        headerBtnView.addSubview(headerBtn)
        headerView.addSubview(bottomLineView)
        headerView.addSubview(headerBtnView)
        
        tableView.tableHeaderView = headerView
        
    }
    @objc func groupBtnPressed(){
        print("Btn pressed")
    }
    
    func avatarWasTapped(indexPath: IndexPath) {
        //we have to check if chat is private. grab user (userId of other user is on recent chat)from FB and to Profile view
        let recentChat = recentChats[indexPath.row]
        
        //check chat type
        if recentChat[kTYPE] as! String == kPRIVATE{
            
            let otherUserId = recentChat[kWITHUSERUSERID] as! String
            
            //get user from Fb
            reference(.User).document(otherUserId).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                
                if snapshot.exists{
                    let otherUserDictionary = snapshot.data() as! NSDictionary
                    //create a model
                    let otherUser = FUser(_dictionary: otherUserDictionary)
                    
                    self.navigateToUserProfile(user:otherUser)
                    
                }
            }
            
        }
        
    }
    
    func navigateToUserProfile(user: FUser){
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as! ProfileTVC
        profileVC.user = user
        //navigate
        navigationController?.pushViewController(profileVC, animated: true)
        
    }
    //MARK: - Search bar functions
    
    //default allrecentChats
   
    func filterContentFoSearchText(searchText:String, scope: String = "All"){
        //filter all user array to contain only names with specific test
        filteredChats = recentChats.filter { (recentChat) -> Bool in
            //condition
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        }
        //reload data on table view
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //call filter function
        filterContentFoSearchText(searchText: searchController.searchBar.text!)
    }
}


