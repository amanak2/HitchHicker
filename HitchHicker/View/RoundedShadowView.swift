//
//  RoundedShadowView.swift
//  HitchHicker
//
//  Created by Aman Chawla on 23/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        setView()
    }
    
    func setView() {
        //rounded corner
        self.layer.cornerRadius = 5.0
        
        //Shadow
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
    }

}
