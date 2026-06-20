import CoreLocation
import CoreMotion
import Foundation
import HealthKit

final class RunSessionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var currentPaceSecondsPerKilometer: TimeInterval?
    @Published private(set) var currentHeartRate: Double?
    @Published private(set) var cadenceStepsPerMinute: Double?
    @Published private(set) var locationMessage = "等待定位权限"
    @Published private(set) var healthMessage = "等待心率数据"
    @Published private(set) var motionMessage = "等待步频数据"

    private let locationManager: CLLocationManager
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    private var timer: Timer?
    private var startedAt: Date?
    private var pausedAt: Date?
    private var pausedDuration: TimeInterval = 0
    private var lastLocation: CLLocation?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var heartRateAnchor: HKQueryAnchor?

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

    var heartRateText: String {
        guard let currentHeartRate else { return "--" }
        return "\(Int(currentHeartRate.rounded()))"
    }

    var cadenceText: String {
        guard let cadenceStepsPerMinute else { return "--" }
        return "\(Int(cadenceStepsPerMinute.rounded()))"
    }

    var aerobicEffectText: String {
        guard let currentHeartRate else { return "待心率" }

        switch currentHeartRate {
        case ..<120:
            return elapsedTime >= 300 ? "恢复" : "热身"
        case 120..<140:
            return "基础"
        case 140..<160:
            return "提升"
        default:
            return "强化"
        }
    }

    var aerobicEffectDetail: String {
        guard let currentHeartRate else { return "连接心率后评估" }

        switch currentHeartRate {
        case ..<120:
            return "轻松有氧"
        case 120..<140:
            return "耐力打底"
        case 140..<160:
            return "有氧提升"
        default:
            return "高强刺激"
        }
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
        currentHeartRate = nil
        cadenceStepsPerMinute = nil
        lastLocation = nil
        isRunning = true
        isPaused = false
        locationMessage = "正在陪你跑"
        healthMessage = "正在连接心率"
        motionMessage = "正在读取步频"

        locationManager.startUpdatingLocation()
        startHeartRateUpdates()
        startCadenceUpdates(from: Date())
        startTimer()
    }

    func pauseRun() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        pausedAt = Date()
        locationMessage = "已暂停"
        motionMessage = "已暂停"
        locationManager.stopUpdatingLocation()
        stopCadenceUpdates()
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
        motionMessage = "正在读取步频"
        locationManager.startUpdatingLocation()
        startCadenceUpdates(from: Date())
        startTimer()
    }

    func finishRun() {
        isRunning = false
        isPaused = false
        startedAt = nil
        pausedAt = nil
        locationMessage = "本次跑步已结束"
        healthMessage = "本次跑步已结束"
        motionMessage = "本次跑步已结束"
        locationManager.stopUpdatingLocation()
        stopHeartRateUpdates()
        stopCadenceUpdates()
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

    private func startHeartRateUpdates() {
        #if targetEnvironment(simulator)
        healthMessage = "请在真机连接 Apple Watch 心率"
        return
        #else
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            healthMessage = "当前设备不支持心率数据"
            return
        }

        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error {
                    self?.healthMessage = error.localizedDescription
                    return
                }

                guard success else {
                    self?.healthMessage = "未获得心率权限"
                    return
                }

                self?.healthMessage = "等待 Apple Watch 心率"
                self?.beginHeartRateQuery(heartRateType)
            }
        }
        #endif
    }

    private func beginHeartRateQuery(_ heartRateType: HKQuantityType) {
        stopHeartRateUpdates()

        let startDate = startedAt ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: heartRateAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, error in
            self?.handleHeartRateSamples(samples, anchor: newAnchor, error: error)
        }

        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            self?.handleHeartRateSamples(samples, anchor: newAnchor, error: error)
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    private func handleHeartRateSamples(_ samples: [HKSample]?, anchor: HKQueryAnchor?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error {
                self?.healthMessage = error.localizedDescription
                return
            }

            self?.heartRateAnchor = anchor

            guard let sample = (samples as? [HKQuantitySample])?.sorted(by: { $0.endDate < $1.endDate }).last else {
                return
            }

            self?.currentHeartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            self?.healthMessage = "心率已更新"
        }
    }

    private func stopHeartRateUpdates() {
        if let heartRateQuery {
            healthStore.stop(heartRateQuery)
        }
        heartRateQuery = nil
    }

    private func startCadenceUpdates(from startDate: Date) {
        guard CMPedometer.isStepCountingAvailable() else {
            motionMessage = "当前设备不支持步频"
            return
        }

        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.motionMessage = error.localizedDescription
                    return
                }

                guard let data else { return }

                if #available(iOS 9.0, *), let currentCadence = data.currentCadence {
                    self.cadenceStepsPerMinute = currentCadence.doubleValue * 60
                } else {
                    let duration = max(Date().timeIntervalSince(startDate), 1)
                    self.cadenceStepsPerMinute = data.numberOfSteps.doubleValue / duration * 60
                }

                self.motionMessage = "步频已更新"
            }
        }
    }

    private func stopCadenceUpdates() {
        pedometer.stopUpdates()
    }
}
