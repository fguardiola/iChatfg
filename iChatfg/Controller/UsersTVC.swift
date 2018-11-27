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

class UsersTVC: UITableViewController, UISearchResultsUpdating {

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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allUsers.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        cell.congfigureCell(fUser: allUsers[indexPath.row], indexPath: indexPath)

        return cell
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
    
}
