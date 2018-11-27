//
//  SettingsTVC.swift
//  iChatfg
//
//  Created by 67621177 on 27/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //APPLE STYLE SETTNG TITLE
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

   
    @IBAction func logOutPressed(_ sender: Any) {
        //Implement logout function
        FUser.logOutCurrentUser { (success) in
            if success{
                //have to navigate to wellcomeVC
                let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
                
                self.present(vc, animated: true, completion: nil)
            }
        }
        
    }
    
}
