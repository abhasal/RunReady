import Foundation

/// Stateless utility for all unit conversions and display formatting.
/// All internal storage is in SI units (meters, seconds); this layer handles presentation only.
enum UnitConversionService {

    // MARK: - Distance

    static let metersPerMile: Double = 1609.344
    static let metersPerKilometer: Double = 1000.0

    static func metersToMiles(_ meters: Double) -> Double {
        meters / metersPerMile
    }

    static func milesToMeters(_ miles: Double) -> Double {
        miles * metersPerMile
    }

    static func metersToKilometers(_ meters: Double) -> Double {
        meters / metersPerKilometer
    }

    static func kilometersToMeters(_ km: Double) -> Double {
        km * metersPerKilometer
    }

    /// Convert meters to the preferred display unit
    static func metersToPreferred(_ meters: Double, unit: UnitSystem) -> Double {
        switch unit {
        case .metric:   return metersToKilometers(meters)
        case .imperial: return metersToMiles(meters)
        }
    }

    // MARK: - Pace  (seconds per meter → display string)

    /// Seconds per meter to seconds per preferred unit (km or mile)
    static func paceSecondsPerMeter(toPreferred secondsPerMeter: Double, unit: UnitSystem) -> Double {
        switch unit {
        case .metric:   return secondsPerMeter * metersPerKilometer
        case .imperial: return secondsPerMeter * metersPerMile
        }
    }

    /// Returns "M:SS" string for a pace in seconds-per-preferred-unit
    static func paceString(secondsPerUnit: Double) -> String {
        guard secondsPerUnit.isFinite, secondsPerUnit > 0 else { return "--:--" }
        let totalSeconds = Int(secondsPerUnit.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Full pace label including unit, e.g. "5:42 /km"
    static func formattedPace(secondsPerMeter: Double, unit: UnitSystem) -> String {
        let converted = paceSecondsPerMeter(toPreferred: secondsPerMeter, unit: unit)
        return "\(paceString(secondsPerUnit: converted)) /\(unit.distanceUnit)"
    }

    // MARK: - Distance display

    static func formattedDistance(_ meters: Double, unit: UnitSystem, decimals: Int = 2) -> String {
        let value = metersToPreferred(meters, unit: unit)
        return String(format: "%.\(decimals)f \(unit.distanceUnit)", value)
    }

    static func formattedDistanceCompact(_ meters: Double, unit: UnitSystem) -> String {
        let value = metersToPreferred(meters, unit: unit)
        if value >= 10 {
            return String(format: "%.1f \(unit.distanceUnit)", value)
        } else {
            return String(format: "%.2f \(unit.distanceUnit)", value)
        }
    }

    // MARK: - Duration

    static func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    /// Compact form: "1h 23m" or "42m"
    static func formattedDurationCompact(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }

    // MARK: - Calories

    static func formattedCalories(_ kcal: Double) -> String {
        String(format: "%.0f kcal", kcal)
    }

    // MARK: - Speed (for live tracking display)

    static func speedMPSToDisplayPace(_ mps: Double, unit: UnitSystem) -> String {
        guard mps > 0.1 else { return "--:--" }
        let secondsPerMeter = 1.0 / mps
        return formattedPace(secondsPerMeter: secondsPerMeter, unit: unit)
    }

    // MARK: - Threshold helpers used by PredictionEngine

    /// Convert a threshold specified in km (for readability) to meters
    static func kmToMeters(_ km: Double) -> Double { km * 1000 }

    /// Convert a threshold specified in miles to meters
    static func milesToMetersThreshold(_ miles: Double) -> Double { miles * metersPerMile }
}
