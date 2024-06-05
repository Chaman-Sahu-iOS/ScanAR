//
//  CustomLocationManager.swift
//  CaptureSample
//
//  Created by Chaman on 19/05/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationType {
    case startingPoint
    case endingPoint
}

class CustomLocationManager: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private(set) var startingPoint: CLLocation?
    private(set) var endingPoint: CLLocation?
    
    var currentLocation: CLLocation?
    var locationType: LocationType?
    
    static let shared = CustomLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(for locationType: LocationType) {
        self.locationType = locationType
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        switch locationType {
        case .startingPoint:
            startingPoint = location
            print("Starting Point: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        case .endingPoint:
            endingPoint = location
            print("Ending Point: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        case .none:
            break
        }
        
        stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
