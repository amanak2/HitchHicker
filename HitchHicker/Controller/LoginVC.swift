//
//  LoginVC.swift
//  HitchHicker
//
//  Created by Aman Chawla on 24/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    @IBAction func cancleBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
