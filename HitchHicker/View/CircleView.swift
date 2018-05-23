//
//  CircleView.swift
//  HitchHicker
//
//  Created by Aman Chawla on 23/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit

class CircleView: UIView {

    @IBInspectable var borderColor: UIColor? {
        didSet {
            setView()
        }
    }
    
    override func awakeFromNib() {
        setView()
    }
    
    func setView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }

}
