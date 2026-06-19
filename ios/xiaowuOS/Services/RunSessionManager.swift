import CoreLocation
import Foundation

final class RunSessionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var currentPaceSecondsPerKilometer: TimeInterval?
    @Published private(set) var locationMessage = "等待定位权限"

    private let locationManager: CLLocationManager
    private var timer: Timer?
    private var startedAt: Date?
    private var pausedAt: Date?
    private var pausedDuration: TimeInterval = 0
    private var lastLocation: CLLocation?

    override init() {
        let locationManager = CLLocationManager()
        self.locationManager = locationManager
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }

    var distanceText: String {
        Formatters.distance(distanceMeters)
    }

    var elapsedText: String {
        Formatters.stopwatch(elapsedTime)
    }

    var paceText: String {
        guard let currentPaceSecondsPerKilometer else { return "--'--\"" }
        return Formatters.pace(currentPaceSecondsPerKilometer)
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startRun() {
        if authorizationStatus == .notDetermined {
            requestLocationPermission()
        }

        startedAt = Date()
        pausedAt = nil
        pausedDuration = 0
        elapsedTime = 0
        distanceMeters = 0
        currentPaceSecondsPerKilometer = nil
        lastLocation = nil
        isRunning = true
        isPaused = false
        locationMessage = "正在陪你跑"

        locationManager.startUpdatingLocation()
        startTimer()
    }

    func pauseRun() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pausedAt = Date()
        locationMessage = "已暂停"
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
    }

    func resumeRun() {
        guard isRunning, isPaused else { return }
        if let pausedAt {
            pausedDuration += Date().timeIntervalSince(pausedAt)
        }
        pausedAt = nil
        isPaused = false
        lastLocation = nil
        locationMessage = "继续跑"
        locationManager.startUpdatingLocation()
        startTimer()
    }

    func finishRun() {
        isRunning = false
        isPaused = false
        startedAt = nil
        pausedAt = nil
        locationMessage = "本次跑步已结束"
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationMessage = "定位已就绪"
        case .denied, .restricted:
            locationMessage = "定位权限未开启"
        case .notDetermined:
            locationMessage = "等待定位权限"
        @unknown default:
            locationMessage = "定位状态未知"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRunning, !isPaused else { return }

        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 30 {
            if let lastLocation {
                let segment = location.distance(from: lastLocation)
                if segment < 100 {
                    distanceMeters += segment
                }
            }
            lastLocation = location
        }

        updatePace()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationMessage = error.localizedDescription
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let startedAt, isRunning, !isPaused else { return }
        elapsedTime = Date().timeIntervalSince(startedAt) - pausedDuration
        updatePace()
    }

    private func updatePace() {
        guard distanceMeters >= 20 else {
            currentPaceSecondsPerKilometer = nil
            return
        }

        currentPaceSecondsPerKilometer = elapsedTime / (distanceMeters / 1_000)
    }
}
