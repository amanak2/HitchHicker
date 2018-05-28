//
//  DriverAnotation.swift
//  HitchHicker
//
//  Created by Aman Chawla on 27/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import Foundation
import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, withKey key: String){
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
    
    func updateAnnotation(annotationPostion annotation: DriverAnnotation, withCoordinate coordinate: CLLocationCoordinate2D) {
        var location = self.coordinate
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        UIView.animate(withDuration: 0.1) {
            self.coordinate = location
        }
    }
}
