//
//  Constants.swift
//  ScanAR
//
//  Created by Chaman on 20/05/24.
//

import Foundation
import CoreLocation

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension CLLocationCoordinate2D {
    func toDMS() -> (latitude: String, longitude: String) {
        func degreesMinutesSeconds(from decimalDegrees: Double) -> (degrees: Int, minutes: Int, seconds: Double) {
            let degrees = Int(decimalDegrees)
            let minutesDecimal = (decimalDegrees - Double(degrees)) * 60
            let minutes = Int(minutesDecimal)
            let seconds = (minutesDecimal - Double(minutes)) * 60
            return (degrees: degrees, minutes: minutes, seconds: seconds)
        }

        func formatDMS(degrees: Int, minutes: Int, seconds: Double, directionPositive: String, directionNegative: String) -> String {
            let direction = degrees >= 0 ? directionPositive : directionNegative
            return String(format: "%d° %d' %.2f\" %@", abs(degrees), abs(minutes), abs(seconds), direction)
        }

        let latDMS = degreesMinutesSeconds(from: latitude)
        let lonDMS = degreesMinutesSeconds(from: longitude)

        let latitudeString = formatDMS(degrees: latDMS.degrees, minutes: latDMS.minutes, seconds: latDMS.seconds, directionPositive: "N", directionNegative: "S")
        let longitudeString = formatDMS(degrees: lonDMS.degrees, minutes: lonDMS.minutes, seconds: lonDMS.seconds, directionPositive: "E", directionNegative: "W")

        return (latitude: latitudeString, longitude: longitudeString)
    }
}

