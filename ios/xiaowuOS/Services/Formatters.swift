import Foundation

enum NumberFormatters {
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

enum Formatters {
    static func distance(_ meters: Double) -> String {
        if meters >= 1_000 {
            return String(format: "%.2f 公里", meters / 1_000)
        }

        return "\(Int(meters)) 米"
    }

    static func heartRate(_ value: Double?) -> String {
        guard let value else { return "暂无数据" }
        return "\(Int(value.rounded())) 次/分"
    }

    static func duration(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "暂无数据" }
        let hours = Int(interval) / 3_600
        let minutes = (Int(interval) % 3_600) / 60
        return "\(hours)小时\(minutes)分"
    }

    static func stopwatch(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func pace(_ secondsPerKilometer: TimeInterval) -> String {
        guard secondsPerKilometer.isFinite else { return "--'--\"" }
        let minutes = Int(secondsPerKilometer) / 60
        let seconds = Int(secondsPerKilometer) % 60
        return String(format: "%d'%02d\"/公里", minutes, seconds)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
