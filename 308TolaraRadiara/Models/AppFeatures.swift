import Foundation
import SwiftUI

enum ActivityMode: String, Codable, CaseIterable, Identifiable {
    case outdoor
    case beach
    case hiking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .outdoor: return "Outdoor"
        case .beach: return "Beach"
        case .hiking: return "Hiking"
        }
    }

    var icon: String {
        switch self {
        case .outdoor: return "figure.walk"
        case .beach: return "beach.umbrella.fill"
        case .hiking: return "figure.hiking"
        }
    }

    var detail: String {
        switch self {
        case .outdoor: return "Everyday city & park activity"
        case .beach: return "Higher sun exposure near water"
        case .hiking: return "Longer days with varied shade"
        }
    }

    var thresholds: AlertThresholds {
        switch self {
        case .outdoor: return AlertThresholds(low: 200, high: 800)
        case .beach: return AlertThresholds(low: 120, high: 550)
        case .hiking: return AlertThresholds(low: 250, high: 900)
        }
    }

    func tip(for value: Double) -> String {
        switch self {
        case .outdoor:
            switch value {
            case ..<200: return "Mild for outdoor plans — good window for a walk."
            case 200..<500: return "Moderate. Prefer tree shade around midday."
            case 500..<800: return "High for city outdoors. Shorten open-sun time."
            default: return "Extreme. Move activities indoors or fully shaded."
            }
        case .beach:
            switch value {
            case ..<150: return "Gentle beach light — still use light SPF."
            case 150..<400: return "Reflective sand/water raises exposure. Reapply sunscreen."
            case 400..<600: return "Strong beach radiation. Limit peak-hour sunbathing."
            default: return "Extreme beach levels. Seek shade and cover up now."
            }
        case .hiking:
            switch value {
            case ..<250: return "Comfortable trail levels — hydrate and enjoy."
            case 250..<550: return "Rising trail exposure. Use hat and sleeves on ridgelines."
            case 550..<900: return "High alpine/open-trail radiation. Plan shady rest stops."
            default: return "Extreme trail radiation. Descend to cover if possible."
            }
        }
    }
}

enum SunSensitivity: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var detail: String {
        switch self {
        case .low: return "I rarely burn and stay outdoors easily."
        case .medium: return "I tan or burn depending on the day."
        case .high: return "I burn quickly and need cautious limits."
        }
    }

    var icon: String {
        switch self {
        case .low: return "sun.max"
        case .medium: return "sun.min.fill"
        case .high: return "thermometer.sun.fill"
        }
    }

    var thresholds: AlertThresholds {
        switch self {
        case .low: return AlertThresholds(low: 250, high: 900)
        case .medium: return AlertThresholds(low: 200, high: 750)
        case .high: return AlertThresholds(low: 120, high: 550)
        }
    }
}

enum ReadingTag: String, Codable, CaseIterable, Identifiable {
    case park
    case balcony
    case trip
    case beach
    case work
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .park: return "Park"
        case .balcony: return "Balcony"
        case .trip: return "Trip"
        case .beach: return "Beach"
        case .work: return "Work"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .park: return "leaf.fill"
        case .balcony: return "building.2.fill"
        case .trip: return "suitcase.fill"
        case .beach: return "beach.umbrella.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

enum ChallengeKind: String, Codable, CaseIterable, Identifiable {
    case noonChecker
    case modeExplorer
    case tagCollector
    case weekWarrior

    var id: String { rawValue }

    var title: String {
        switch self {
        case .noonChecker: return "Noon Checker"
        case .modeExplorer: return "Mode Explorer"
        case .tagCollector: return "Tag Collector"
        case .weekWarrior: return "Week Warrior"
        }
    }

    var detail: String {
        switch self {
        case .noonChecker: return "Log a reading at noon (11–13) for 7 days"
        case .modeExplorer: return "Try all 3 activity modes"
        case .tagCollector: return "Use 4 different location tags"
        case .weekWarrior: return "Keep a 7-day activity streak"
        }
    }

    var icon: String {
        switch self {
        case .noonChecker: return "clock.fill"
        case .modeExplorer: return "switch.2"
        case .tagCollector: return "tag.fill"
        case .weekWarrior: return "flame.fill"
        }
    }

    var goal: Int {
        switch self {
        case .noonChecker: return 7
        case .modeExplorer: return 3
        case .tagCollector: return 4
        case .weekWarrior: return 7
        }
    }
}

struct ReminderSettings: Codable, Equatable {
    var dailyEnabled: Bool = false
    var hour: Int = 12
    var minute: Int = 0
    var thresholdAlertsEnabled: Bool = true

    var reminderDateComponents: DateComponents {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        return comps
    }
}

enum SmartTipService {
    static func tip(
        value: Double,
        mode: ActivityMode,
        streakDays: Int,
        hour: Int = Calendar.current.component(.hour, from: Date())
    ) -> String {
        if streakDays >= 7 {
            return "Nice \(streakDays)-day streak. \(mode.tip(for: value))"
        }
        if streakDays >= 3 {
            return "Streak day \(streakDays). \(timeAwareTip(value: value, mode: mode, hour: hour))"
        }
        return timeAwareTip(value: value, mode: mode, hour: hour)
    }

    private static func timeAwareTip(value: Double, mode: ActivityMode, hour: Int) -> String {
        let base = mode.tip(for: value)
        switch hour {
        case 5..<9:
            return "Morning window: \(base)"
        case 9..<11:
            return "Late morning: \(base)"
        case 11..<15:
            return "Peak sun hours: \(base)"
        case 15..<18:
            return "Afternoon fade: \(base)"
        case 18..<21:
            return "Evening ease: \(base)"
        default:
            return "Night levels are low. \(base)"
        }
    }
}

struct DayWindow: Identifiable {
    let id = UUID()
    let startHour: Int
    let endHour: Int
    let average: Double

    var label: String {
        "\(startHour):00 – \(endHour):00"
    }
}

enum ForecastService {
    /// Finds the gentlest consecutive outdoor window for today using the simulator curve.
    static func bestWindow(
        for date: Date = Date(),
        highThreshold: Double,
        lengthHours: Int = 2
    ) -> DayWindow? {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        var candidates: [(start: Int, avg: Double)] = []

        for hour in 6...(20 - lengthHours) {
            var sum = 0.0
            var ok = true
            for offset in 0..<lengthHours {
                guard let slot = cal.date(byAdding: .hour, value: hour + offset, to: startOfDay) else {
                    ok = false
                    break
                }
                let value = SolarSimulator.radiation(for: slot)
                if value >= highThreshold { ok = false }
                sum += value
            }
            if ok {
                candidates.append((hour, sum / Double(lengthHours)))
            }
        }

        if let best = candidates.min(by: { $0.avg < $1.avg }) {
            return DayWindow(startHour: best.start, endHour: best.start + lengthHours, average: best.avg)
        }

        var fallback: [(start: Int, avg: Double)] = []
        for hour in 6...(20 - lengthHours) {
            var sum = 0.0
            for offset in 0..<lengthHours {
                guard let slot = cal.date(byAdding: .hour, value: hour + offset, to: startOfDay) else { continue }
                sum += SolarSimulator.radiation(for: slot)
            }
            fallback.append((hour, sum / Double(lengthHours)))
        }
        guard let best = fallback.min(by: { $0.avg < $1.avg }) else { return nil }
        return DayWindow(startHour: best.start, endHour: best.start + lengthHours, average: best.avg)
    }

    static func hourlyForecast(for date: Date = Date()) -> [(hour: Int, value: Double)] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return (6...20).compactMap { hour in
            guard let slot = cal.date(byAdding: .hour, value: hour, to: start) else { return nil }
            return (hour, SolarSimulator.radiation(for: slot))
        }
    }
}
