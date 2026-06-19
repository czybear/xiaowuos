import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    @Published private(set) var isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationMessage = "等待授权"
    @Published private(set) var todayMetrics: [HealthMetric] = []
    @Published private(set) var bodyMetrics: [HealthMetric] = []
    @Published private(set) var recentRuns: [RunWorkout] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current

    private enum HealthKitError: LocalizedError {
        case typeUnavailable

        var errorDescription: String? {
            "当前设备缺少需要的健康数据类型"
        }
    }

    func requestAuthorizationAndRefresh() {
        #if targetEnvironment(simulator)
        authorizationMessage = "请在真机连接 Apple 健康"
        errorMessage = nil
        todayMetrics = []
        bodyMetrics = []
        recentRuns = []
        #else
        guard isHealthDataAvailable else {
            authorizationMessage = "这台设备暂不支持健康数据"
            return
        }

        var readTypes = Set<HKObjectType>()
        [
            HKQuantityTypeIdentifier.stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .heartRate,
            .restingHeartRate
        ].compactMap { HKObjectType.quantityType(forIdentifier: $0) }
            .forEach { readTypes.insert($0) }

        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }
        readTypes.insert(HKWorkoutType.workoutType())

        let shareTypes: Set<HKSampleType> = [
            HKWorkoutType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error {
                    self?.authorizationMessage = "授权失败"
                    self?.errorMessage = error.localizedDescription
                    return
                }

                self?.authorizationMessage = success ? "已连接 Apple 健康" : "未获得健康权限"
                self?.refreshHealthData()
            }
        }
        #endif
    }

    func refreshHealthData() {
        #if targetEnvironment(simulator)
        authorizationMessage = "请在真机连接 Apple 健康"
        errorMessage = nil
        todayMetrics = []
        bodyMetrics = []
        recentRuns = []
        #else
        guard isHealthDataAvailable else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let startOfDay = calendar.startOfDay(for: Date())
                let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

                async let steps = fetchSum(.stepCount, unit: .count(), start: startOfDay)
                async let distance = fetchSum(.distanceWalkingRunning, unit: .meter(), start: startOfDay)
                async let energy = fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: startOfDay)
                async let heartRate = fetchMostRecentQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
                async let restingHeartRate = fetchMostRecentQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
                async let sleepDuration = fetchSleepDuration(start: yesterday)
                async let runs = fetchRecentRuns()

                let today = [
                    HealthMetric(title: "今日步数", value: NumberFormatters.integer.string(from: NSNumber(value: try await steps)) ?? "0", subtitle: "来自 Apple 健康", systemImage: "shoeprints.fill"),
                    HealthMetric(title: "步行跑步距离", value: Formatters.distance(try await distance), subtitle: "今天累计", systemImage: "figure.run"),
                    HealthMetric(title: "活动能量", value: "\(Int(try await energy)) 千卡", subtitle: "今天消耗", systemImage: "flame.fill")
                ]

                let body = [
                    HealthMetric(title: "最近心率", value: Formatters.heartRate(try await heartRate), subtitle: "最近一次记录", systemImage: "heart.fill"),
                    HealthMetric(title: "静息心率", value: Formatters.heartRate(try await restingHeartRate), subtitle: "最近一次记录", systemImage: "waveform.path.ecg"),
                    HealthMetric(title: "睡眠", value: Formatters.duration(try await sleepDuration), subtitle: "近 24 小时", systemImage: "bed.double.fill")
                ]

                let recentRunValues = (try? await runs) ?? []

                await MainActor.run {
                    todayMetrics = today
                    bodyMetrics = body
                    recentRuns = recentRunValues
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
        #endif
    }

    private func fetchSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date) async throws -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.typeUnavailable
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }

            healthStore.execute(query)
        }
    }

    private func fetchMostRecentQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.typeUnavailable
        }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchSleepDuration(start: Date) async throws -> TimeInterval {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeUnavailable
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let duration = (samples as? [HKCategorySample] ?? [])
                    .filter { $0.value != HKCategoryValueSleepAnalysis.awake.rawValue }
                    .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                continuation.resume(returning: duration)
            }

            healthStore.execute(query)
        }
    }

    private func fetchRecentRuns() async throws -> [RunWorkout] {
        let type = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 5, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    RunWorkout(
                        date: workout.startDate,
                        distanceMeters: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                        duration: workout.duration,
                        activeEnergyKilocalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                    )
                }

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }
}
