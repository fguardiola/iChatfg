//
//  RegisterVC.swift
//  iChatfg
//
//  Created by 67621177 on 26/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
import ProgressHUD

class RegisterVC: UIViewController {
    //variables
    var email: String!
    var password: String!
    var avatarImage: String?
    
    
    @IBOutlet weak var avatarImg: UIImage!
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var surnameTxt: UITextField!
    @IBOutlet weak var countryTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var phneTxt: UITextField!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
  
    // MARK: - IBActions

    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismissKeyBoard()
        clearTextFields()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneBtnPressed(_ sender: Any) {
        dismissKeyBoard()
        ProgressHUD.show("Registering...")
        //check if all parameters have a value
        guard email.isNotEmpty, password.isNotEmpty, let name = nameTxt.text, name.isNotEmpty, let surname = surnameTxt.text, surname.isNotEmpty, let country = countryTxt.text, country.isNotEmpty, let city = cityTxt.text, city.isNotEmpty, let phone = phneTxt.text, phone.isNotEmpty else {
            ProgressHUD.showError("All fields are required!!")
            return
        }
        // Call registration helper
        FUser.registerUserWith(email: email, password: password, firstName: name, lastName: surname) { (error) in
            if error != nil{
                ProgressHUD.dismiss()
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            
            //this point we have a user saved locally and on firebase under users but with no avatar
            // phoneNumber, city or country saved
            self.registerUser()
        }
    }
    
    //helpers
    func registerUser(){
        //update FB userTable and local copy. We know we have all the values on the text fields
        
        let fullName = nameTxt.text! + " " + surnameTxt.text!
        
        var tempDictionary: Dictionary = [
            kFIRSTNAME: nameTxt.text!, kLASTNAME: surnameTxt.text!, kFULLNAME: fullName, kCOUNTRY: countryTxt.text!, kCITY: cityTxt.text!, kPHONE:phneTxt.text!
        ] as [String : Any]
        
        // check if user has selected avatarImage
        if avatarImage == nil{
            //we have to prepare image to be stored on FB. Data of mage String format
            imageFromInitials(firstName: nameTxt.text!, lastName: surnameTxt.text!) { (avatarFromInitials) in
                //convert UIimage to data
                let avatarIMGData = avatarFromInitials.jpegData(compressionQuality: 0.7)
                //cnvert it to string
                let avatarString = avatarIMGData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                tempDictionary[kAVATAR] = avatarString
                //finish registration
                self.finishRegistration(withValues: tempDictionary)
                
            }
            
        }else{
            //convert UIimage to data
            let avatarIMGData = avatarImg?.jpegData(compressionQuality: 0.7)
            //cnvert it to string
            let avatarString = avatarIMGData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatarString
            //finish registration
            finishRegistration(withValues: tempDictionary)
            
        }
        
    }
    
    func finishRegistration(withValues: [String: Any]){
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            if error != nil{
                DispatchQueue.main.async {
                    ProgressHUD.showError(error?.localizedDescription)
                    debugPrint(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            //continue app flow
            self.goToApp()
            
        }
        
    }
    
    func goToApp(){
        dismissKeyBoard()
        clearTextFields()
        //send login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
    }
    
    func dismissKeyBoard(){
        self.view.endEditing(true)
    }
    func clearTextFields(){
        self.nameTxt.text = ""
        self.surnameTxt.text = ""
        self.countryTxt.text = ""
        self.cityTxt.text = ""
        self.phneTxt.text = ""
    }
}
