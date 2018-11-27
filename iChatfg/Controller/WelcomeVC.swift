//
//  ViewController.swift
//  iChatfg
//
//  Created by 67621177 on 26/11/2018.
//  Copyright © 2018 67621177. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeVC: UIViewController {
    //Variables
    
    //Mark: - Oulets
    @IBOutlet weak var emailTxt: UITextField!
    
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var confirmPassTxt: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func loginBtnPressed(_ sender: Any) {
        self.dismissKeyBoard()
        guard let email = emailTxt.text, email.isNotEmpty, let password = passwordTxt.text, password.isNotEmpty else{
            ProgressHUD.showError("Email and Password are required")
            return
        }
        
         loginUser()
    }
    
    @IBAction func registerBtnPressed(_ sender: Any) {
       self.dismissKeyBoard()
    
        guard let email = emailTxt.text, email.isNotEmpty, let password = passwordTxt.text, password.isNotEmpty, let confirm = confirmPassTxt.text, confirm.isNotEmpty  else{
            ProgressHUD.showError("Email, Password & Confirm Password are required")
            return
        }
        if passwordTxt.text == confirmPassTxt.text{
            registerUser()
        }else {
            ProgressHUD.showError("Passwords don't match!!")
        }
        
       
    }
    @IBAction func backgroundTap(_ sender: Any) {
       print("Dismiss")
        self.dismissKeyBoard()
    }
    
    func dismissKeyBoard(){
        self.view.endEditing(true)
    }
    func clearTextFields(){
        self.emailTxt.text = ""
        self.confirmPassTxt.text = ""
        self.passwordTxt.text = ""
    }
    
    func loginUser(){
       print("About to login user!!!")
       ProgressHUD.show("Login...")
        FUser.loginUserWith(email: emailTxt.text!, password: passwordTxt.text!) { (error) in
            if error != nil{
                ProgressHUD.showError(error?.localizedDescription)
                return
            }else{
                self.goToApp()
            }
        }
       
    }
    
    func registerUser(){
        print("About to Register user!!!")
        performSegue(withIdentifier: "goToRegister", sender: self)
        clearTextFields()
        dismissKeyBoard()
    }
    
    func goToApp(){
        ProgressHUD.dismiss()
        clearTextFields()
        dismissKeyBoard()
        
        //send login notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        //Go to app
    }
    
    //MARK: Navigtion
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRegister"{
            guard let destination = segue.destination as? RegisterVC else { return }
            destination.email = emailTxt.text
            destination.password = passwordTxt.text
        }
    }
}

