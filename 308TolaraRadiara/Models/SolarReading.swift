import Foundation

struct SolarReading: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let value: Double
    var tag: ReadingTag?

    init(id: UUID = UUID(), date: Date = Date(), value: Double, tag: ReadingTag? = nil) {
        self.id = id
        self.date = date
        self.value = value
        self.tag = tag
    }

    var intensityLabel: String {
        switch value {
        case ..<200: return "Low"
        case 200..<500: return "Moderate"
        case 500..<800: return "High"
        default: return "Extreme"
        }
    }

    var intensityFraction: Double {
        min(max(value / 1200.0, 0), 1)
    }
}

struct AlertThresholds: Codable, Equatable {
    var low: Double
    var high: Double

    static let `default` = AlertThresholds(low: 200, high: 800)
}

struct DailyAggregate: Identifiable {
    let id: String
    let date: Date
    let average: Double
    let count: Int
}

struct ComparisonResult: Equatable {
    let percent: Double
    let baselineAverage: Double
    let currentAverage: Double

    var isUp: Bool { percent >= 0 }

    var headline: String {
        let absPercent = abs(percent)
        if absPercent < 1 {
            return "About the same as usual"
        }
        let direction = isUp ? "higher" : "lower"
        return String(format: "%.0f%% %@ than usual", absPercent, direction)
    }
}
