import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @AppStorage("tr_sound_enabled") private var soundEnabled = true
    @AppStorage("tr_haptics_enabled") private var hapticsEnabled = true
    @State private var showResetAlert = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Picker("Appearance", selection: Binding(
                                get: { store.appearance },
                                set: { store.setAppearance($0) }
                            )) {
                                ForEach(AppAppearance.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $soundEnabled) {
                                Label {
                                    Text("Sound")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                } icon: {
                                    Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .padding(.vertical, 8)
                            .onChange(of: soundEnabled) { newValue in
                                HapticService.soundEnabled = newValue
                                if newValue {
                                    HapticService.play(1104)
                                }
                                NotificationService.reschedule(from: store.reminders)
                            }

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            Toggle(isOn: $hapticsEnabled) {
                                Label {
                                    Text("Haptic Feedback")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                } icon: {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundStyle(Color("AppPrimary"))
                                        .frame(width: 28)
                                }
                            }
                            .tint(Color("AppPrimary"))
                            .padding(.vertical, 8)
                            .onChange(of: hapticsEnabled) { newValue in
                                HapticService.hapticsEnabled = newValue
                                if newValue {
                                    HapticService.light()
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminders")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))

                            Toggle(isOn: Binding(
                                get: { store.reminders.dailyEnabled },
                                set: { enabled in
                                    var next = store.reminders
                                    next.dailyEnabled = enabled
                                    store.updateReminders(next)
                                }
                            )) {
                                Text("Daily check-in")
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .tint(Color("AppPrimary"))

                            if store.reminders.dailyEnabled {
                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(Color("AppPrimary"))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .onChange(of: reminderTime) { newValue in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    var next = store.reminders
                                    next.hour = comps.hour ?? 12
                                    next.minute = comps.minute ?? 0
                                    store.updateReminders(next)
                                }
                            }

                            Divider().background(Color("AppTextSecondary").opacity(0.25))

                            Toggle(isOn: Binding(
                                get: { store.reminders.thresholdAlertsEnabled },
                                set: { enabled in
                                    var next = store.reminders
                                    next.thresholdAlertsEnabled = enabled
                                    store.updateReminders(next)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Threshold alerts")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text("Local push when a reading leaves your range")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .tint(Color("AppPrimary"))
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stats")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            HStack {
                                statCell("Readings", store.stats.itemsCreated)
                                statCell("Sessions", store.stats.sessionsCompleted)
                                statCell("Streak", store.stats.streakDays)
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .appNavigationChrome("Settings")
            .onAppear {
                var comps = DateComponents()
                comps.hour = store.reminders.hour
                comps.minute = store.reminders.minute
                reminderTime = Calendar.current.date(from: comps) ?? reminderTime
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                }
            } message: {
                Text("This clears readings, alerts, and achievements on this device.")
            }
        }
    }

    private func statCell(_ title: String, _ value: Int) -> some View {
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

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color("AppPrimary"))
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
