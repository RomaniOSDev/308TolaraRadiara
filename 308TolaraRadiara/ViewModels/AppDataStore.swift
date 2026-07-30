import Foundation
import SwiftUI
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var readings: [SolarReading] = []
    @Published var thresholds: AlertThresholds = .default
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var currentReading: SolarReading?
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var activityMode: ActivityMode = .outdoor
    @Published var selectedTag: ReadingTag? = nil
    @Published var appearance: AppAppearance = .dark
    @Published var reminders: ReminderSettings = ReminderSettings()

    private let defaults = UserDefaults.standard
    private let readingsKey = "tr_readings"
    private let thresholdsKey = "tr_thresholds"
    private let statsKey = "tr_stats"
    private let unlockedKey = "tr_unlocked"
    private let onboardingKey = "tr_onboarding"
    private let modeKey = "tr_activity_mode"
    private let appearanceKey = "tr_appearance"
    private let remindersKey = "tr_reminders"
    private let tagKey = "tr_selected_tag"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false
    private var lastThresholdNotifyAt: Date?

    private init() {
        load()
    }

    // MARK: - Readings

    @discardableResult
    func refreshCurrentReading(appendToHistory: Bool = true) -> SolarReading {
        let reading = SolarReading(
            date: Date(),
            value: SolarSimulator.radiation(),
            tag: selectedTag
        )
        currentReading = reading
        if appendToHistory {
            appendReading(reading)
        }
        return reading
    }

    func appendReading(_ reading: SolarReading) {
        readings.insert(reading, at: 0)
        if readings.count > 400 {
            readings = Array(readings.prefix(400))
        }
        stats.itemsCreated += 1
        if let tag = reading.tag, !stats.usedTags.contains(tag.rawValue) {
            stats.usedTags.append(tag.rawValue)
        }
        recordActivity()
        recordNoonCheckIfNeeded(for: reading.date)
        persist()
        evaluateAchievements()
        evaluateChallenges()
        maybeNotifyThreshold(for: reading.value)
        HapticService.medium()
        HapticService.play(1104)
    }

    func dailyAggregates() -> [DailyAggregate] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: readings) { reading -> String in
            let comps = cal.dateComponents([.year, .month, .day], from: reading.date)
            return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        }
        return grouped.compactMap { key, values -> DailyAggregate? in
            guard let first = values.first else { return nil }
            let day = cal.startOfDay(for: first.date)
            let avg = values.map(\.value).reduce(0, +) / Double(values.count)
            return DailyAggregate(id: key, date: day, average: avg, count: values.count)
        }
        .sorted { $0.date > $1.date }
    }

    func filteredReadings(from start: Date?, to end: Date?, minValue: Double?, maxValue: Double?) -> [SolarReading] {
        readings.filter { reading in
            if let start, reading.date < start { return false }
            if let end, reading.date > end { return false }
            if let minValue, reading.value < minValue { return false }
            if let maxValue, reading.value > maxValue { return false }
            return true
        }
    }

    // MARK: - Comparison

    func comparison(againstDays days: Int) -> ComparisonResult? {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        guard let periodStart = cal.date(byAdding: .day, value: -days, to: todayStart) else { return nil }

        let todayReadings = readings.filter { $0.date >= todayStart }
        let baseline = readings.filter { $0.date >= periodStart && $0.date < todayStart }

        let todayValues: [Double]
        if todayReadings.isEmpty {
            todayValues = [SolarSimulator.radiation()]
        } else {
            todayValues = todayReadings.map(\.value)
        }

        let baselineValues: [Double]
        if baseline.isEmpty {
            baselineValues = (0..<days).compactMap { offset -> Double? in
                guard let day = cal.date(byAdding: .day, value: -offset - 1, to: todayStart) else { return nil }
                return SolarSimulator.radiation(for: day)
            }
        } else {
            baselineValues = baseline.map(\.value)
        }

        guard !todayValues.isEmpty, !baselineValues.isEmpty else { return nil }
        let current = todayValues.reduce(0, +) / Double(todayValues.count)
        let base = baselineValues.reduce(0, +) / Double(baselineValues.count)
        guard base > 0 else { return nil }
        let percent = ((current - base) / base) * 100
        return ComparisonResult(percent: percent, baselineAverage: base, currentAverage: current)
    }

    // MARK: - Mode / Theme / Reminders

    func setActivityMode(_ mode: ActivityMode, applyThresholds: Bool = true) {
        activityMode = mode
        if !stats.usedModes.contains(mode.rawValue) {
            stats.usedModes.append(mode.rawValue)
        }
        if applyThresholds {
            thresholds = mode.thresholds
            stats.alertsConfigured = true
        }
        persist()
        evaluateChallenges()
        HapticService.light()
    }

    func setSelectedTag(_ tag: ReadingTag?) {
        selectedTag = tag
        if let tag {
            defaults.set(tag.rawValue, forKey: tagKey)
        } else {
            defaults.removeObject(forKey: tagKey)
        }
    }

    func setAppearance(_ value: AppAppearance) {
        appearance = value
        defaults.set(value.rawValue, forKey: appearanceKey)
        HapticService.light()
    }

    func updateReminders(_ settings: ReminderSettings, requestPermissionIfNeeded: Bool = true) {
        reminders = settings
        persistReminders()
        if settings.dailyEnabled || settings.thresholdAlertsEnabled {
            if requestPermissionIfNeeded {
                NotificationService.requestPermission { [weak self] granted in
                    guard let self else { return }
                    if granted {
                        NotificationService.reschedule(from: self.reminders)
                    } else if settings.dailyEnabled {
                        self.reminders.dailyEnabled = false
                        self.persistReminders()
                    }
                }
            } else {
                NotificationService.reschedule(from: settings)
            }
        } else {
            NotificationService.reschedule(from: settings)
        }
    }

    // MARK: - Alerts

    func saveThresholds(low: Double, high: Double) {
        let lo = min(low, high)
        let hi = max(low, high)
        thresholds = AlertThresholds(low: lo, high: hi)
        let wasConfigured = stats.alertsConfigured
        stats.alertsConfigured = true
        if !wasConfigured {
            stats.itemsCreated = max(stats.itemsCreated, 1)
        } else {
            stats.itemsCreated += 1
        }
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.success()
    }

    func applySensitivity(_ sensitivity: SunSensitivity) {
        stats.sensitivity = sensitivity.rawValue
        thresholds = sensitivity.thresholds
        stats.alertsConfigured = true
        persist()
    }

    func isOutsideThresholds(_ value: Double) -> Bool {
        value <= thresholds.low || value >= thresholds.high
    }

    // MARK: - Challenges

    func challengeProgress(_ kind: ChallengeKind) -> Int {
        switch kind {
        case .noonChecker:
            return min(stats.noonStreakDays, kind.goal)
        case .modeExplorer:
            return min(stats.usedModes.count, kind.goal)
        case .tagCollector:
            return min(stats.usedTags.count, kind.goal)
        case .weekWarrior:
            return min(stats.streakDays, kind.goal)
        }
    }

    func isChallengeComplete(_ kind: ChallengeKind) -> Bool {
        stats.completedChallenges.contains(kind.rawValue) || challengeProgress(kind) >= kind.goal
    }

    private func evaluateChallenges() {
        for kind in ChallengeKind.allCases {
            guard challengeProgress(kind) >= kind.goal else { continue }
            guard !stats.completedChallenges.contains(kind.rawValue) else { continue }
            stats.completedChallenges.append(kind.rawValue)
            enqueueBanner(kind.title)
        }
        persist()
    }

    // MARK: - Insights

    func recordInsightSession() {
        stats.sessionsCompleted += 1
        recordActivity()
        persist()
        evaluateAchievements()
    }

    // MARK: - Onboarding / Reset

    func completeOnboarding(sensitivity: SunSensitivity = .medium) {
        applySensitivity(sensitivity)
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func resetAll() {
        readings = []
        thresholds = .default
        stats = UserStats()
        unlockedAchievements = []
        currentReading = nil
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        activityMode = .outdoor
        selectedTag = nil
        reminders = ReminderSettings()
        persist()
        NotificationService.reschedule(from: reminders)
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !unlockedAchievements.contains(key) else { continue }
            unlockedAchievements.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Persistence helpers

    private func maybeNotifyThreshold(for value: Double) {
        if let last = lastThresholdNotifyAt, Date().timeIntervalSince(last) < 300 {
            return
        }
        guard isOutsideThresholds(value) else { return }
        lastThresholdNotifyAt = Date()
        NotificationService.notifyThresholdIfNeeded(
            value: value,
            thresholds: thresholds,
            enabled: reminders.thresholdAlertsEnabled
        )
    }

    private func recordNoonCheckIfNeeded(for date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        guard (11...13).contains(hour) else { return }

        let formatter = dayFormatter()
        let today = formatter.string(from: date)
        if stats.lastNoonDay == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date),
           formatter.string(from: yesterday) == stats.lastNoonDay {
            stats.noonStreakDays += 1
        } else {
            stats.noonStreakDays = 1
        }
        stats.lastNoonDay = today
    }

    private func recordActivity() {
        let formatter = dayFormatter()
        let today = formatter.string(from: Date())
        if stats.lastActiveDay.isEmpty {
            stats.streakDays = 1
            stats.lastActiveDay = today
            return
        }
        if stats.lastActiveDay == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           formatter.string(from: yesterday) == stats.lastActiveDay {
            stats.streakDays += 1
        } else {
            stats.streakDays = 1
        }
        stats.lastActiveDay = today
    }

    private func dayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        if let data = defaults.data(forKey: readingsKey),
           let decoded = try? JSONDecoder().decode([SolarReading].self, from: data) {
            readings = decoded
        }
        if let data = defaults.data(forKey: thresholdsKey),
           let decoded = try? JSONDecoder().decode(AlertThresholds.self, from: data) {
            thresholds = decoded
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(arr)
        }
        if let mode = ActivityMode(rawValue: defaults.string(forKey: modeKey) ?? "") {
            activityMode = mode
        }
        if let appearanceRaw = defaults.string(forKey: appearanceKey),
           let value = AppAppearance(rawValue: appearanceRaw) {
            appearance = value
        }
        if let data = defaults.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            reminders = decoded
        }
        if let tagRaw = defaults.string(forKey: tagKey),
           let tag = ReadingTag(rawValue: tagRaw) {
            selectedTag = tag
        }
        currentReading = readings.first
        NotificationService.reschedule(from: reminders)
    }

    private func persistReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            defaults.set(data, forKey: remindersKey)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(readings) {
            defaults.set(data, forKey: readingsKey)
        }
        if let data = try? JSONEncoder().encode(thresholds) {
            defaults.set(data, forKey: thresholdsKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(activityMode.rawValue, forKey: modeKey)
        defaults.set(appearance.rawValue, forKey: appearanceKey)
        persistReminders()
        if let tag = selectedTag {
            defaults.set(tag.rawValue, forKey: tagKey)
        }
    }
}
