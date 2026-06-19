import Foundation

struct HealthMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
}

struct RunWorkout: Identifiable {
    let id = UUID()
    let date: Date
    let distanceMeters: Double
    let duration: TimeInterval
    let activeEnergyKilocalories: Double?

    var paceSecondsPerKilometer: TimeInterval? {
        guard distanceMeters > 0 else { return nil }
        return duration / (distanceMeters / 1_000)
    }
}
