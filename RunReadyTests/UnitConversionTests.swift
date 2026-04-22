import XCTest
@testable import RunReady

final class UnitConversionTests: XCTestCase {

    // MARK: - Distance conversions

    func testMetersToKilometers() {
        XCTAssertEqual(UnitConversionService.metersToKilometers(1000), 1.0, accuracy: 0.001)
        XCTAssertEqual(UnitConversionService.metersToKilometers(5000), 5.0, accuracy: 0.001)
        XCTAssertEqual(UnitConversionService.metersToKilometers(42195), 42.195, accuracy: 0.001)
    }

    func testMetersToMiles() {
        XCTAssertEqual(UnitConversionService.metersToMiles(1609.344), 1.0, accuracy: 0.001)
        XCTAssertEqual(UnitConversionService.metersToMiles(5000), 3.107, accuracy: 0.001)
        XCTAssertEqual(UnitConversionService.metersToMiles(42195), 26.219, accuracy: 0.001)
    }

    func testRoundTripMetricImperial() {
        let originalMeters = 10_000.0
        let miles = UnitConversionService.metersToMiles(originalMeters)
        let backToMeters = UnitConversionService.milesToMeters(miles)
        XCTAssertEqual(backToMeters, originalMeters, accuracy: 0.01)
    }

    func testRoundTripKilometers() {
        let originalMeters = 21_097.5
        let km = UnitConversionService.metersToKilometers(originalMeters)
        let backToMeters = UnitConversionService.kilometersToMeters(km)
        XCTAssertEqual(backToMeters, originalMeters, accuracy: 0.01)
    }

    // MARK: - Pace formatting

    func testPaceStringFiveMinuteKm() {
        // 5:00 min/km = 300 sec/km → 0.3 sec/meter
        let secondsPerMeter = 300.0 / 1000.0
        let paceStr = UnitConversionService.formattedPace(secondsPerMeter: secondsPerMeter, unit: .metric)
        XCTAssertEqual(paceStr, "5:00 /km")
    }

    func testPaceStringEightMinuteMile() {
        // 8:00 min/mile = 480 sec/mile → sec/meter = 480 / 1609.344
        let secondsPerMeter = 480.0 / UnitConversionService.metersPerMile
        let paceStr = UnitConversionService.formattedPace(secondsPerMeter: secondsPerMeter, unit: .imperial)
        XCTAssertEqual(paceStr, "8:00 /mi")
    }

    func testPaceStringZeroReturnsPlaceholder() {
        let paceStr = UnitConversionService.formattedPace(secondsPerMeter: 0, unit: .metric)
        XCTAssertEqual(paceStr, "--:-- /km")
    }

    func testPaceStringInvalidReturnsPlaceholder() {
        let paceStr = UnitConversionService.formattedPace(secondsPerMeter: .infinity, unit: .metric)
        XCTAssertEqual(paceStr, "--:-- /km")
    }

    // MARK: - Duration formatting

    func testDurationUnderOneHour() {
        XCTAssertEqual(UnitConversionService.formattedDuration(30 * 60), "30:00")
        XCTAssertEqual(UnitConversionService.formattedDuration(5 * 60 + 30), "5:30")
    }

    func testDurationOverOneHour() {
        XCTAssertEqual(UnitConversionService.formattedDuration(3660), "1:01:00")
        XCTAssertEqual(UnitConversionService.formattedDuration(7384), "2:03:04")
    }

    // MARK: - Distance display

    func testFormattedDistanceMetric() {
        let result = UnitConversionService.formattedDistance(10_000, unit: .metric, decimals: 2)
        XCTAssertEqual(result, "10.00 km")
    }

    func testFormattedDistanceImperial() {
        let result = UnitConversionService.formattedDistance(1609.344, unit: .imperial, decimals: 2)
        XCTAssertEqual(result, "1.00 mi")
    }

    // MARK: - metersToPreferred

    func testMetersToPreferredMetric() {
        XCTAssertEqual(UnitConversionService.metersToPreferred(5000, unit: .metric), 5.0, accuracy: 0.001)
    }

    func testMetersToPreferredImperial() {
        XCTAssertEqual(UnitConversionService.metersToPreferred(1609.344, unit: .imperial), 1.0, accuracy: 0.001)
    }
}
