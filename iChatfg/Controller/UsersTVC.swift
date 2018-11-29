//
//  UsersTVC.swift
//  iChatfg
//
//  Created by 67621177 on 27/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTVC: UITableViewController, UISearchResultsUpdating, UITableViewCellDelegate {
   

    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    
    var allUsers : [FUser] = []
    var filteredUsers: [FUser] = []
    // to order susers in alphabetic groups
    var allUsersGroupped = NSDictionary() as! [ String: [FUser]]
    var sectionTitleList: [String] = []
    
    //search controller
    var searchController =  UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //city is the first option on segment control
        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        //trick to not display more items than the esntries we have. Another option style separator = none
        tableView.tableFooterView = UIView()
        
        
        //search bar set
        navigationItem.searchController = self.searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        self.loadUsers(filter: kCITY)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != ""{
            return 1
        }else{
            //user are gonna be ordered alphabetically so thats the sections.
            return allUsersGroupped.count
        }
       
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != ""{
            //filterd users is going to keep the result of the search
            return filteredUsers.count
        }else {
            //get section title. Array that contains titles of groups
            //THink we should add checks to see if next variables exist guard let
            let sectionTitle = sectionTitleList[section]
            let usersOnSection = allUsersGroupped[sectionTitle]
            return usersOnSection!.count
        }
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        //cells mst be created dinamicalyy
        var user: FUser
        
        //user is searching data would be on filteredUsers
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredUsers[indexPath.row]
        }else{
            let sectionTitle = sectionTitleList[indexPath.section]
            
            
            let usersOnSection = allUsersGroupped[sectionTitle]
            
            user = usersOnSection![indexPath.row]
        }
        
        cell.congfigureCell(fUser: user, indexPath: indexPath)
        cell.delegate = self

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //when we click on user we want to createa chatroom if does not exist
        //get user we want to chat with
        var user: FUser
        
        //user is searching data would be on filteredUsers
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredUsers[indexPath.row]
        }else{
            let sectionTitle = sectionTitleList[indexPath.section]
            
            
            let usersOnSection = allUsersGroupped[sectionTitle]
            
            user = usersOnSection![indexPath.row]
        }
        
        //create a chat. Store on recents for both users
        startPrivateChat(user1: FUser.currentUser()!, user2: user)
    }
    
    //MARK: - Tableview delegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //no title if searching
        if searchController.isActive && searchController.searchBar.text != ""{
            return ""
        }else{
            //return a,b,c...
            return sectionTitleList[section]
        }
    
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != ""{
            return nil
        }else{
            //return a,b,c...
            return sectionTitleList
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    //MARK: - Search bar functions
    
    //default all
    func filterContentFoSearchText(searchText:String, scope: String = "All"){
        //filter all user array to contain only names with specific test
        filteredUsers = allUsers.filter { (user) -> Bool in
            //condition
            return user.firstname.lowercased().contains(searchText.lowercased())
        }
        //reload data on table view
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //call filter function
        filterContentFoSearchText(searchText: searchController.searchBar.text!)
    }
    
    //load users depending on city,country, all
    func loadUsers(filter: String){
        ProgressHUD.show()
        var query : Query!
        
        switch filter {
            case kCITY:
                query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
            case kCOUNTRY:
                query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
            default:
                //All users
                query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            
            //reset user arrays
            self.allUsers = []
            self.sectionTitleList = []
            self.allUsersGroupped = [:]
            
            if error != nil{
                debugPrint(error?.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                return
            }
            
            //check if we have a snapshot
            guard let snapshot = snapshot else{
                ProgressHUD.dismiss()
              //  self.tableView.reloadData() ///leave it as it is
                return
            }
            
            //do something with snapshot
            if !snapshot.isEmpty{
                //get documents as dictionary
                for document in snapshot.documents{
                    let userDictionary = document.data() as NSDictionary
                    
                    let fUser = FUser(_dictionary: userDictionary)
                    //user can be current user
                    if fUser.objectId != FUser.currentId(){
                        // append user to array
                        self.allUsers.append(fUser)
                    }
                    
                }
              //organize users. split users
                self.splitDataInSections()
                self.tableView.reloadData()
            }
            ProgressHUD.dismiss()
            self.tableView.reloadData()
            
            
        }
        
    }
    
    @IBAction func segmentCotrolChange(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            //kCITY
            self.loadUsers(filter: kCITY)
        case 1:
            //kCountry
            self.loadUsers(filter: kCOUNTRY)
        case 2:
            //all
            self.loadUsers(filter: "")
        default:
            return 
        }
        
    }
    
    fileprivate func splitDataInSections(){
        //Allusers are ordered by fristname from FB
        var sectionTitle: String = ""
        
        //loop through all users
        
        for i in 0..<allUsers.count {
            
            let user = allUsers[i]
            print(user.firstname)
            let firstNameChar = user.firstname.first!
            let firstNameString = String(firstNameChar)
            
            if firstNameString != sectionTitle{
                //add new title to array
                sectionTitle = firstNameString
                //create an empty array for users with that letter
                self.allUsersGroupped[sectionTitle] = []
                self.sectionTitleList.append(firstNameString)
            }
            //add user to groupedUsers
            self.allUsersGroupped[sectionTitle]?.append(user)
        }
        print(allUsersGroupped)
        
    }
    
    //MARK: - Delegate methods
    func avatarWasTapped(indexPath: IndexPath) {
        print("Cell tapped: \(indexPath)")
        
        //navigate to profile vc we need a user to pass
        var user : FUser
        
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredUsers[indexPath.row]
        }else{
            let sectionTitle = sectionTitleList[indexPath.section]
            let usersOnSection = allUsersGroupped[sectionTitle]
            user = usersOnSection![indexPath.row]
        }
        
        guard let profileTVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userProfile") as? ProfileTVC
            else{ return }
        
        profileTVC.user = user
        
        //navigate to TVC
        navigationController?.pushViewController(profileTVC, animated: true)
    }
    
    
}
