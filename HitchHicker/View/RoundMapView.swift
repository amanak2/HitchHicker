//
//  RoundMapView.swift
//  HitchHicker
//
//  Created by Aman Chawla on 30/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {

    override func awakeFromNib() {
        setView()
    }
    
    func setView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }

}
