import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Progress")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            HStack {
                                metric("Readings", store.stats.itemsCreated)
                                metric("Sessions", store.stats.sessionsCompleted)
                                metric("Streak", store.stats.streakDays)
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Challenges")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            ForEach(ChallengeKind.allCases) { challenge in
                                challengeRow(challenge)
                                if challenge != ChallengeKind.allCases.last {
                                    Divider().background(Color("AppTextSecondary").opacity(0.25))
                                }
                            }
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AchievementKind.allCases, id: \.rawValue) { kind in
                            achievementCard(kind)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .appNavigationChrome("Achievements")
        }
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func challengeRow(_ kind: ChallengeKind) -> some View {
        let progress = store.challengeProgress(kind)
        let done = store.isChallengeComplete(kind)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: kind.icon)
                    .foregroundStyle(done ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(kind.detail)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                Text("\(progress)/\(kind.goal)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
            }
            ProgressView(value: Double(progress), total: Double(kind.goal))
                .tint(Color("AppAccent"))
        }
        .padding(.vertical, 4)
        .opacity(done ? 1 : 0.9)
    }

    private func achievementCard(_ kind: AchievementKind) -> some View {
        let unlocked = store.unlockedAchievements.contains(kind.rawValue) || kind.isUnlocked(stats: store.stats)
        let progress = min(kind.progress(stats: store.stats), kind.goal)
        return SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: kind.icon)
                    .font(.title2)
                    .foregroundStyle(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
                    .shadow(color: unlocked ? Color("AppPrimary").opacity(0.45) : .clear, radius: 8)
                Text(kind.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(kind.detail)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                ProgressView(value: Double(progress), total: Double(kind.goal))
                    .tint(Color("AppAccent"))
                Text("\(progress)/\(kind.goal)")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(unlocked ? 1 : 0.72)
        }
    }
}
