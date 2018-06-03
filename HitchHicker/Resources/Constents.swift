//
//  Constents.swift
//  HitchHicker
//
//  Created by Aman Chawla on 03/06/18.
//  Copyright © 2018 Aman Chawla. All rights reserved.
//

import Foundation

//Account
let ACCOUNT_IS_DRIVER = "isDriver"
let ACCOUNT_PICKUP_MODE_ENABLED = "pickupModeEnabled"
let ACCOUNT_TYPE_PASSENGER = "PASSENGER"
let ACCOUNT_TYPE_DRIVER =  "DRIVER"

//location
let COORDINATE = "coordinate"

//trip
let TRIP_COORDINATE = "tripCoordinate"
let TRIP_ACCEPTED = "tripAccepted"
let TRIP_IN_PROGRESS = "tripInProgress"

//user
let USER_PICKUP_COORDINATE = "pickupCoordinate"
let USER_DESTINATION_COORDINATE = "destinationCoordinate"
let USER_PASSENGER_KEY = "passengerKey"
let USER_IS_DRIVER = "userIsDriver"

//driver
let DRIVER_KEY = "driverKey"
let DRIVER_IS_ON_TRIP = "driverIsOnTrip"

//map annotation
let ANNO_DRIVER = "driverAnnotation"
let ANNO_PICKUP = "curruntLocationAnnotation"
let ANNO_DESTINATION = "destinationAnnotation"

//map region
let REGION_PICKUP = "pickup"
let REGION_DESTINATION = "destination"

//storyboard
let MAIN_STORYBOARD = "Main"

//view controller
let VC_LEFT_PANEL = "leftSidePanelVC"
let VC_HOME = "HomeVC"
let VC_LOGIN = "LoginVC"
let VC_PICKUP = "PickupVC"

//table View
let CELL_LOCATION = "LocationCell"

//UI messages
let MSG_SIGNIN_SIGNUP = "Sign Up / Login"
let MSG_SIGNOUT = "Sign Out"
let MSG_PICKUP_MODE_ENABLED = "PICKUP MODE ENABLED"
let MSG_PICKUP_MODE_DISABLED = "PICKUP MODE DISABLED"
let MSG_REQUEST_RIDE = "REQUEST RIDE"
let MSG_START_TRIP = "START TRIP"
let MSG_END_TRIP = "END TRIP"
let MSG_GET_DIRECTION = "GET DIRECTIONS"
let MSG_CANCEL_TRIP = "CANCEL TRIP"
let MSG_DRIVER_COMING = "DRIVER COMING"
let MSG_ON_TRIP = "ON TRIP"
let MSG_PASSENGER_PICKUP_POINT = "Passenger Pickup Point"
let MSG_PASSENGER_DESTINATION = "Passenger Destination"

//error messages
let ERROR_MSG_NO_MATCHES_FOUND = "No matches found, please try again."
let ERROR_MSG_INVALID_EMAIL = "Sorry, The email entered is incorrect. Please try another email."
let ERROR_MSG_EMAIL_ALREADY_IN_USE = "It apears the email you have entered is already in use, please try again."
let ERROR_MSG_WRONG_PASSWORD = "The password you have tried is incorrect. Please try again."
let ERROR_MSG_UNEXPECTED_ERROR = "These seems to be an unexpectd error. Please try again."
