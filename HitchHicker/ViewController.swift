//
//  ViewController.swift
//  HitchHicker
//
//  Created by Aman Chawla on 23/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var actionBtn: RoundedShadowBtn!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }

    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateBtn(shouldLoad: true, withMessage: nil)
    }
    
}

