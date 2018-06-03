//
//  ViewController.swift
//  HitchHicker
//
//  Created by Aman Chawla on 23/05/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation
import RevealingSplashView

enum AnnotationType {
    case pickup
    case destination
    case driver
}

enum ButtonAction {
    case requestRide
    case getDirectionsToPassenger
    case getDirectionsToDestination
    case startTrip
    case endTrip
}

class HomeVC: UIViewController, Alertable {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowBtn!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var cancelTripBtn: UIButton!
    
    var tableView = UITableView()
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var selectedItemPlacemark: MKPlacemark? = nil
    var route: MKRoute!
    
    var delegate: CenterVCDelegate?
    
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    
    var actionForButton: ButtonAction = .requestRide
    
    var revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        destinationTextField.delegate = self
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocAuth()
        centerMapOnUserLocation()
        
        DataService.instance.REF_DRIVERS.observe(.value, with:  { (snapshot) in
            self.loadDriverAnnotationFromFB()
            
            DataService.instance.passengerIsOnTrip(passengerKey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(FitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withkey: driverKey)
                }
            })
        })
        
        cancelTripBtn.alpha = 0.0
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripAccepted"] as! Bool
                
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: (Auth.auth().currentUser?.uid)!, handler: { (available) in
                        if let available = available {
                            if available == true {
                                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                pickupVC?.initData(coordiante: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                self.present(pickupVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let currentUserID = Auth.auth().currentUser?.uid
        
        DataService.instance.userIsDriver(userKey: currentUserID!, handler: { (status) in
            if status == true{
                self.buttonForDriverHidden(areHidden: true)
            }
        })
        
        DataService.instance.driverIsOnTrip(driverkey: currentUserID!, handler: { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == currentUserID! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                
                                self.dropPinFor(placemark: pickupPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                                
                                self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                                
                                self.actionForButton = .getDirectionsToPassenger
                                self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                                
                                self.buttonForDriverHidden(areHidden: false)
                            }
                        }
                    }
                })
            }
        })
        
        connectUserAndDriverForTrip()
        
        DataService.instance.REF_TRIPS.observe(.childRemoved, with: { (removeTripSnapshot) in
            let removeTripDict = removeTripSnapshot.value as? [String: AnyObject]
            if removeTripDict?["driverKey"] != nil {
                DataService.instance.REF_DRIVERS.child(removeTripDict?["driverKey"] as! String).updateChildValues(["driverIsOnTrip": false])
            }
                
            DataService.instance.userIsDriver(userKey: currentUserID!, handler: { (isDriver) in
                if isDriver == true {
                    self.removeOverlaysAndAnnotations(forDriver: false, forPassenger: true)
                } else {
                    self.cancelTripBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.actionBtn.animateBtn(shouldLoad: false, withMessage: "REQUEST RIDE")
                    
                    self.destinationTextField.isUserInteractionEnabled = true
                    self.destinationTextField.text = ""
                    
                    self.removeOverlaysAndAnnotations(forDriver: false, forPassenger: true)
                    self.centerMapOnUserLocation()
                }
            })
            
        })
    }
    
    func buttonForDriverHidden(areHidden: Bool) {
        if areHidden {
            self.actionBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.cancelTripBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.actionBtn.isHidden = true
            self.cancelTripBtn.isHidden = true
            self.centerMapBtn.isHidden = true
        } else {
            self.actionBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.cancelTripBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.actionBtn.isHidden = false
            self.cancelTripBtn.isHidden = false
            self.centerMapBtn.isHidden = false
        }
    }
    
    func checkLocAuth() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }
    
    func loadDriverAnnotationFromFB() {
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.childSnapshot(forPath: "userIsDriver").value as? Bool == true {
                        if driver.hasChild("coordinate"){
                            if driver.childSnapshot(forPath: "pickupModeEnabled").value as? Bool == true {
                                if let driverDict = driver.value as? Dictionary<String, AnyObject> {
                                    let coordinateArray = driverDict["coordinate"] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    var driverIsVisiable: Bool {
                                        return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation {
                                                if driverAnnotation.key == driver.key {
                                                    driverAnnotation.updateAnnotation(annotationPostion: driverAnnotation, withCoordinate: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                        })
                                    }
                                    if !driverIsVisiable {
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            } else {
                                for annotation in self.mapView.annotations {
                                    if annotation.isKind(of: DriverAnnotation.self) {
                                        if let annotation = annotation as? DriverAnnotation {
                                            if annotation.key == driver.key {
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
        revealingSplashView.heartAttack = true
    }
    
    func connectUserAndDriverForTrip() {
        
        let currentUserID = Auth.auth().currentUser?.uid
        
        DataService.instance.userIsDriver(userKey: currentUserID!) { (status) in
            if status == false {
                DataService.instance.REF_TRIPS.child(currentUserID!).observe(.value, with: { (tripSnapshot) in
                    let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                    
                    if tripDict?["tripAccepted"] as? Bool == true {
                        self.removeOverlaysAndAnnotations(forDriver: false, forPassenger: true)
                        
                        let driverID = tripDict?["driverKey"] as! String
                        
                        let pickupCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                        
                        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (driverSnapshot) in
                            if let driverSnapshot = driverSnapshot.children.allObjects as? [DataSnapshot] {
                                for driver in driverSnapshot {
                                    if driver.key == driverID {
                                        let driverCoordinateArray = driver.childSnapshot(forPath: "coordinate").value as! NSArray
                                        let driverCoordinate = CLLocationCoordinate2D(latitude: driverCoordinateArray[0] as! CLLocationDegrees, longitude: driverCoordinateArray[1] as! CLLocationDegrees)
                                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                                        let driverMapItem = MKMapItem(placemark: driverPlacemark)
                                        
                                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, withKey: currentUserID!)
                                        //let driverAnnotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driverID)
                                        
                                        self.mapView.addAnnotation(passengerAnnotation)
                                        self.searchMapKitForResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                                        self.actionBtn.animateBtn(shouldLoad: false, withMessage: "DRIVER COMING")
                                        self.actionBtn.isUserInteractionEnabled = false
                                    }
                                }
                            }
                        })
                        
                        let tripKey = tripDict?["passengerKey"] as! String
                        
                        DataService.instance.REF_TRIPS.child(tripKey).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                            if tripDict?["tripInProgress"] as? Bool == true {
                                self.removeOverlaysAndAnnotations(forDriver: true, forPassenger: true)
                                
                                let destinationCoordinateArray = tripDict?["destinationCoordinate"] as! NSArray
                                let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                                let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                                
                                self.dropPinFor(placemark: destinationPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: pickupMapItem, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                                
                                self.actionBtn.setTitle("ON TRIP", for: .normal)
                            }
                        })
                    }
                })
            }
        }
    }
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.00)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func centerMapViewBtnPressed(_ sender: Any) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        if user.hasChild("tripCoordinate") {
                            self.zoom(FitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withkey: nil)
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
    }

    @IBAction func actionBtnPressed(_ sender: Any) {
        buttonSelectorForAction(forAction: actionForButton)
    }
    
    @IBAction func cancelTripBtnPressed(_ sender: Any) {
        
        DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverkey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverkey!)
            }
        })
        
        DataService.instance.passengerIsOnTrip(passengerKey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: (Auth.auth().currentUser?.uid)!, forDriverKey: driverKey!)
            } else {
                UpdateService.instance.cancelTrip(withPassengerKey: (Auth.auth().currentUser?.uid)!, forDriverKey: nil)
            }
        })
        
        self.actionBtn.isUserInteractionEnabled = true
    }
    
    
    @IBAction func menuBtnPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
    
    func buttonSelectorForAction(forAction action: ButtonAction) {
        
        switch action {
        case .requestRide:
            if destinationTextField.text != "" {
                UpdateService.instance.updateTripsWithCoordinatesOnRequest()
                actionBtn.animateBtn(shouldLoad: true, withMessage: nil)
                
                cancelTripBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
                
                self.view.endEditing(true)
                destinationTextField.isUserInteractionEnabled = false
            }
        case .getDirectionsToPassenger:
            DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.child(tripKey!).observe(.value, with: { (tripSnapshot) in
                        let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                        
                        let pickupCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        
                        let pickupMapItem = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate))
                        pickupMapItem.name = "Passenger Pickup Point"
                        pickupMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            })
        case .getDirectionsToDestination:
            DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.child(tripKey!).child("destinationCoordinate").observe(.value, with: { (snapshot) in
                        let destinationCoordinateArray = snapshot.value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                        
                        destinationMapItem.name = "Passenger Destination"
                        destinationMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            })
        case .startTrip:
            DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
                self.removeOverlaysAndAnnotations(forDriver: false, forPassenger: false)
                
                DataService.instance.REF_TRIPS.child(tripKey!).updateChildValues(["tripInProgress": true])
                
                DataService.instance.REF_TRIPS.child(tripKey!).child("destinationCoordinate").observeSingleEvent(of: .value, with: { (coordinateSnapshot) in
                    let destinationCoordinateArray = coordinateSnapshot.value as! NSArray
                    let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                    let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                    
                    self.dropPinFor(placemark: destinationPlacemark)
                    self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                    self.setCustomRegion(forAnnotationType: .destination, withCoordinate: destinationCoordinate)
                    
                    self.actionForButton = .getDirectionsToDestination
                    self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                })
            })
        case .endTrip:
            DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
                    self.buttonForDriverHidden(areHidden: true)
                }
            })
        }
    }
}

extension HomeVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            checkLocAuth()
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true {
                if region.identifier == "pickup" {
                    self.actionForButton = .startTrip
                    self.actionBtn.setTitle("START TRIP", for: .normal)
                } else if region.identifier == "destination" {
                    self.cancelTripBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.cancelTripBtn.isHidden = true
                    self.actionForButton = .endTrip
                    self.actionBtn.setTitle("END TRIP", for: .normal)
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverkey: (Auth.auth().currentUser?.uid)!, handler: { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true {
                if region.identifier == "pickup" {
                    self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                } else if region.identifier == "destination" {
                    self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                }
            }
        })
    }
}

extension HomeVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        
        let currentUserID = Auth.auth().currentUser?.uid
        
        DataService.instance.userIsDriver(userKey: currentUserID!) { (isDriver) in
            if isDriver == true {
                DataService.instance.driverIsOnTrip(driverkey: currentUserID!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(FitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withkey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            } else {
                DataService.instance.passengerIsOnTrip(passengerKey: currentUserID!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(FitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withkey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: self.route.polyline)
        lineRenderer.strokeColor = UIColor.init(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 3.0
        
        shouldPresentLoadingView(false)
        
        return lineRenderer
    }
    
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil {
                self.showAlert((error?.localizedDescription)!)
            } else if response?.mapItems.count == 0 {
                self.showAlert("No Results. Please search again for a diffrent location")
            } else {
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        selectedItemPlacemark = placemark
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapitem: MKMapItem) {
        let request = MKDirectionsRequest()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        
        request.destination = destinationMapitem
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                self.showAlert((error?.localizedDescription)!)
                return
            }
            
            self.route = response.routes[0]
            
            self.mapView.add(self.route.polyline)
            
            self.zoom(FitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withkey: nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
        }
    }
    
    func zoom(FitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withkey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    func removeOverlaysAndAnnotations(forDriver: Bool?, forPassenger: Bool?) {
        
        for annotation in mapView.annotations {
            if let annotaion = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotaion)
            }
            
            if forPassenger! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDriver! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if (overlay is MKPolyline) {
                mapView.remove(overlay)
            }
        }
        
    }
    
    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D) {
        if type == .pickup {
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "pickup")
            manager?.startMonitoring(for: pickupRegion)
        } else if type == .destination {
            let destinatioRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "destination")
            manager?.startMonitoring(for: destinatioRegion)
        }
    }
    
}

extension HomeVC: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == destinationTextField {
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 170)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 18
            tableView.rowHeight = 60
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2) {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2) {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                }
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        
        let currentUserID = Auth.auth().currentUser?.uid
        
        DataService.instance.REF_USERS.child(currentUserID!).child("tripCoordinate").removeValue()
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        centerMapOnUserLocation()
        return true 
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2) {
                self.tableView.frame = CGRect(x: 20, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }) { (finished) in
                for subview in self.view.subviews {
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
    
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "LocationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let currentUserID = Auth.auth().currentUser?.uid
        
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, withKey: currentUserID!)
        mapView.addAnnotation(passengerAnnotation)
        
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child(currentUserID!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        dropPinFor(placemark: selectedMapItem.placemark)
        
        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}

