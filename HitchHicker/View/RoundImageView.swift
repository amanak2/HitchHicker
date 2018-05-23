//
//  RoundImageView.swift
//  HitchHicker
//
//  Created by Aman Chawla on 23/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        setView()
    }
    
    func setView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }

}
