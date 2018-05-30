//
//  PickupVC.swift
//  HitchHicker
//
//  Created by Aman Chawla on 30/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import MapKit

class PickupVC: UIViewController {

    @IBOutlet weak var mapView: RoundMapView!
    
    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    
    var placemark: MKPlacemark!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinForPlacemark(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
    }
    
    func initData(coordiante: CLLocationCoordinate2D, passengerKey: String) {
        self.pickupCoordinate = coordiante
        self.passengerKey = passengerKey
    }
    
    @IBAction func acceptTripBtnPressed(_ sender: Any) {
    }
    
    @IBAction func cancleBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PickupVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation){
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius , regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinForPlacemark(placemark: MKPlacemark){
        
        pin = placemark
        
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
}
