import Foundation
import SwiftData
import CoreLocation

@Model
final class RoutePoint {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitudeMeters: Double
    var horizontalAccuracy: Double
    var speedMPS: Double            // instantaneous speed, -1 if unavailable

    init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitudeMeters: Double = 0,
        horizontalAccuracy: Double = 0,
        speedMPS: Double = -1
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.horizontalAccuracy = horizontalAccuracy
        self.speedMPS = speedMPS
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitudeMeters,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}

extension RoutePoint {
    static func from(_ location: CLLocation) -> RoutePoint {
        RoutePoint(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeMeters: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speedMPS: location.speed
        )
    }
}
