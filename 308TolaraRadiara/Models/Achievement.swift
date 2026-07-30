import Foundation

enum AchievementKind: String, Codable, CaseIterable {
    case firstSetup
    case dailyChecker
    case insightSeeker
    case consistentUser
    case patternExplorer
    case gettingGoing
    case powerUser
    case activeUser

    var title: String {
        switch self {
        case .firstSetup: return "First Setup"
        case .dailyChecker: return "Daily Checker"
        case .insightSeeker: return "Insight Seeker"
        case .consistentUser: return "Consistent User"
        case .patternExplorer: return "Pattern Explorer"
        case .gettingGoing: return "Getting Going"
        case .powerUser: return "Power User"
        case .activeUser: return "Active User"
        }
    }

    var detail: String {
        switch self {
        case .firstSetup: return "Configure your first solar alert thresholds"
        case .dailyChecker: return "Maintain a 7-day tracking streak"
        case .insightSeeker: return "View insights 5 times"
        case .consistentUser: return "Maintain a 30-day tracking streak"
        case .patternExplorer: return "View insights 15 times"
        case .gettingGoing: return "Log 10 solar readings"
        case .powerUser: return "Log 50 solar readings"
        case .activeUser: return "View insights 10 times"
        }
    }

    var icon: String {
        switch self {
        case .firstSetup: return "slider.horizontal.3"
        case .dailyChecker: return "sun.max.fill"
        case .insightSeeker: return "chart.line.uptrend.xyaxis"
        case .consistentUser: return "calendar"
        case .patternExplorer: return "sparkles"
        case .gettingGoing: return "leaf.fill"
        case .powerUser: return "bolt.fill"
        case .activeUser: return "flame.fill"
        }
    }

    var goal: Int {
        switch self {
        case .firstSetup: return 1
        case .dailyChecker: return 7
        case .insightSeeker: return 5
        case .consistentUser: return 30
        case .patternExplorer: return 15
        case .gettingGoing: return 10
        case .powerUser: return 50
        case .activeUser: return 10
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstSetup:
            return stats.alertsConfigured ? max(stats.itemsCreated, 1) : stats.itemsCreated
        case .gettingGoing, .powerUser:
            return stats.itemsCreated
        case .dailyChecker, .consistentUser:
            return stats.streakDays
        case .insightSeeker, .patternExplorer, .activeUser:
            return stats.sessionsCompleted
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        switch self {
        case .firstSetup:
            return stats.alertsConfigured && stats.itemsCreated >= 1
        default:
            return progress(stats: stats) >= goal
        }
    }
}

struct UserStats: Codable, Equatable {
    var itemsCreated: Int = 0
    var sessionsCompleted: Int = 0
    var streakDays: Int = 0
    var lastActiveDay: String = ""
    var alertsConfigured: Bool = false
    var noonStreakDays: Int = 0
    var lastNoonDay: String = ""
    var usedModes: [String] = []
    var usedTags: [String] = []
    var completedChallenges: [String] = []
    var sensitivity: String = SunSensitivity.medium.rawValue

    var sunSensitivity: SunSensitivity {
        SunSensitivity(rawValue: sensitivity) ?? .medium
    }

    enum CodingKeys: String, CodingKey {
        case itemsCreated, sessionsCompleted, streakDays, lastActiveDay, alertsConfigured
        case noonStreakDays, lastNoonDay, usedModes, usedTags, completedChallenges, sensitivity
    }

    init(
        itemsCreated: Int = 0,
        sessionsCompleted: Int = 0,
        streakDays: Int = 0,
        lastActiveDay: String = "",
        alertsConfigured: Bool = false,
        noonStreakDays: Int = 0,
        lastNoonDay: String = "",
        usedModes: [String] = [],
        usedTags: [String] = [],
        completedChallenges: [String] = [],
        sensitivity: String = SunSensitivity.medium.rawValue
    ) {
        self.itemsCreated = itemsCreated
        self.sessionsCompleted = sessionsCompleted
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.alertsConfigured = alertsConfigured
        self.noonStreakDays = noonStreakDays
        self.lastNoonDay = lastNoonDay
        self.usedModes = usedModes
        self.usedTags = usedTags
        self.completedChallenges = completedChallenges
        self.sensitivity = sensitivity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        itemsCreated = try c.decodeIfPresent(Int.self, forKey: .itemsCreated) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try c.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        alertsConfigured = try c.decodeIfPresent(Bool.self, forKey: .alertsConfigured) ?? false
        noonStreakDays = try c.decodeIfPresent(Int.self, forKey: .noonStreakDays) ?? 0
        lastNoonDay = try c.decodeIfPresent(String.self, forKey: .lastNoonDay) ?? ""
        usedModes = try c.decodeIfPresent([String].self, forKey: .usedModes) ?? []
        usedTags = try c.decodeIfPresent([String].self, forKey: .usedTags) ?? []
        completedChallenges = try c.decodeIfPresent([String].self, forKey: .completedChallenges) ?? []
        sensitivity = try c.decodeIfPresent(String.self, forKey: .sensitivity) ?? SunSensitivity.medium.rawValue
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("tr_dataReset")
}
