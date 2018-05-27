//
//  LeftSidePanelVC.swift
//  HitchHicker
//
//  Created by Aman Chawla on 24/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import Firebase

class LeftSidePanelVC: UIViewController {

    let appDelegate = AppDelegate.getAppDelegate()
    
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    @IBOutlet weak var pickupModeLbl: UILabel!
    @IBOutlet weak var userImg: RoundImageView!
    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var logInOutBtn: UIButton!
    
    let currentuserID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLbl.isHidden = true
        
        observePassengerDriver()
        
        if Auth.auth().currentUser == nil {
            self.userAccountTypeLbl.text = ""
            self.userEmailLbl.text = ""
            self.userImg.isHidden = true
            self.logInOutBtn.setTitle("Sign In / Login", for: .normal)
        } else {
            self.userEmailLbl.text = Auth.auth().currentUser?.email
            self.userImg.isHidden = false
            self.userAccountTypeLbl.text = ""
            self.logInOutBtn.setTitle("Sign Out", for: .normal)
        }
    }
    
    func observePassengerDriver() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == self.currentuserID {
                        self.userAccountTypeLbl.text = "PASSENGER"
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == self.currentuserID {
                        self.userAccountTypeLbl.text = "DRIVER"
                        self.pickupModeSwitch.isHidden = false
                        self.pickupModeLbl.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: "pickupModeEnabled").value as! Bool
                        self.pickupModeSwitch.isOn = switchStatus
                    }
                }
            }
        })
    }
    
    @IBAction func switchWasToggled(_ sender: Any) {
        if pickupModeSwitch.isOn == true {
            pickupModeLbl.text = "PICKUP MODE ENABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentuserID!).updateChildValues(["pickupModeEnabled": true])
        } else {
            pickupModeLbl.text = "PICKUP MODE DISABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentuserID!).updateChildValues(["pickupModeEnabled": false])
        }
    }
    
    
    @IBAction func SignupLoginBtnPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                
                self.userImg.isHidden = true
                self.userEmailLbl.text = ""
                self.userAccountTypeLbl.text = ""
                self.pickupModeLbl.text = ""
                self.pickupModeSwitch.isHidden = true
                self.logInOutBtn.setTitle("Sign In / Login", for: .normal)
                
            } catch (let error) {
                print(error)
            }
        }
    }
}
