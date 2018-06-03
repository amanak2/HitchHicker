//
//  LoginVC.swift
//  HitchHicker
//
//  Created by Aman Chawla on 24/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate, Alertable {

    @IBOutlet weak var authBtn: RoundedShadowBtn!
    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var passwordTextField: RoundedCornersTextField!
    @IBOutlet weak var emailTextField: RoundedCornersTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    @IBAction func authBtnPressed(_ sender: Any) {
        if emailTextField.text != nil && passwordTextField.text != nil {
            authBtn.animateBtn(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            
            if let email = emailTextField.text, let password = passwordTextField.text {
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if error == nil {
                        if let user = user {
                            if self.segmentedController.selectedSegmentIndex == 0 {
                                let userData = ["provider": user.providerID] as [String: Any]
                                DataService.instance.createFIRUser(uid: user.uid, userData: userData, isDriver: false)
                            } else {
                                let userData = ["provider": user.providerID,
                                                USER_IS_DRIVER: true,
                                                ACCOUNT_PICKUP_MODE_ENABLED: false,
                                                DRIVER_IS_ON_TRIP: false] as [String: Any]
                                DataService.instance.createFIRUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        if let errorCode = AuthErrorCode(rawValue: error!._code) {
                            switch errorCode {
                            case .wrongPassword:
                                self.showAlert(ERROR_MSG_WRONG_PASSWORD)
                            default:
                                self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
                            }
                        }
                        
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode {
                                    case .invalidEmail:
                                        self.showAlert(ERROR_MSG_INVALID_EMAIL)
                                    default:
                                        self.showAlert(ERROR_MSG_UNEXPECTED_ERROR)
                                    }
                                }
                            } else {
                                if let user = user {
                                    if self.segmentedController.selectedSegmentIndex == 0 {
                                        let userData = ["provider": user.providerID] as [String: Any]
                                        DataService.instance.createFIRUser(uid: user.uid, userData: userData, isDriver: false)
                                    } else {
                                        let userData = ["provider": user.providerID,
                                                        USER_IS_DRIVER: true,
                                                        ACCOUNT_PICKUP_MODE_ENABLED: false,
                                                        DRIVER_IS_ON_TRIP: false] as [String: Any]
                                        DataService.instance.createFIRUser(uid: user.uid, userData: userData, isDriver: true)
                                    }
                                }
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func cancleBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
