import Foundation
import CoreLocation
import Observation

enum ActiveRunState {
    case idle
    case running
    case paused
    case finished
}

@Observable
final class ActiveRunViewModel: NSObject {

    // MARK: - Live metrics
    var state: ActiveRunState = .idle
    var elapsedSeconds: TimeInterval = 0
    var distanceMeters: Double = 0
    var currentPaceSecondsPerMeter: Double = 0
    var routePoints: [RoutePoint] = []
    var locationAuthDenied: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var lastLocation: CLLocation?
    private var timerStartDate: Date?
    private var accumulatedSeconds: TimeInterval = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5   // meters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true  // TODO: Enable "Location updates" background mode in Xcode
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Controls

    func startRun() {
        guard state == .idle || state == .paused else { return }
        requestLocationIfNeeded()
        state = .running
        timerStartDate = Date()
        startTimer()
        locationManager.startUpdatingLocation()
    }

    func pauseRun() {
        guard state == .running else { return }
        state = .paused
        accumulatedSeconds = elapsedSeconds
        stopTimer()
        locationManager.stopUpdatingLocation()
    }

    func resumeRun() {
        guard state == .paused else { return }
        state = .running
        timerStartDate = Date()
        startTimer()
        locationManager.startUpdatingLocation()
    }

    func finishRun() -> RunWorkout? {
        guard state == .running || state == .paused else { return nil }
        stopTimer()
        locationManager.stopUpdatingLocation()
        state = .finished

        guard elapsedSeconds > 0, distanceMeters > 10 else { return nil }

        let run = RunWorkout(
            duration: elapsedSeconds,
            distanceMeters: distanceMeters,
            sourceType: .liveTracked,
            routePoints: routePoints
        )
        return run
    }

    func reset() {
        stopTimer()
        state = .idle
        elapsedSeconds = 0
        distanceMeters = 0
        currentPaceSecondsPerMeter = 0
        routePoints = []
        lastLocation = nil
        accumulatedSeconds = 0
        timerStartDate = nil
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.timerStartDate else { return }
            self.elapsedSeconds = self.accumulatedSeconds + Date().timeIntervalSince(start)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Location permission

    private func requestLocationIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationAuthDenied = true
        default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension ActiveRunViewModel: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            guard location.horizontalAccuracy > 0,
                  location.horizontalAccuracy < 50 else { continue }

            if let last = lastLocation {
                let delta = location.distance(from: last)
                distanceMeters += delta

                let timeDelta = location.timestamp.timeIntervalSince(last.timestamp)
                if timeDelta > 0 && delta > 0 {
                    currentPaceSecondsPerMeter = timeDelta / delta
                }
            }
            lastLocation = location
            routePoints.append(RoutePoint.from(location))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            locationAuthDenied = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthDenied = false
            if state == .running { manager.startUpdatingLocation() }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
}
