import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAlerts = false
    @State private var gaugePulse = false

    private var reading: SolarReading {
        store.currentReading ?? SolarReading(value: 0)
    }

    private var recentValues: [Double] {
        Array(store.readings.prefix(12).map(\.value).reversed())
    }

    private var bestWindow: DayWindow? {
        ForecastService.bestWindow(highThreshold: store.thresholds.high)
    }

    private var hourly: [(hour: Int, value: Double)] {
        ForecastService.hourlyForecast()
    }

    private var vsYesterday: ComparisonResult? {
        store.comparison(againstDays: 1)
    }

    private var vsWeek: ComparisonResult? {
        store.comparison(againstDays: 7)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Activity Mode")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            HStack(spacing: 8) {
                                ForEach(ActivityMode.allCases) { mode in
                                    modeChip(mode)
                                }
                            }
                            Text(store.activityMode.detail)
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    GlassyCard {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Live Radiation")
                                        .font(.headline)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text(store.isOutsideThresholds(reading.value) ? "Outside alert range" : "Within alert range")
                                        .font(.caption)
                                        .foregroundStyle(
                                            store.isOutsideThresholds(reading.value)
                                            ? Color.orange
                                            : Color("AppAccent")
                                        )
                                }
                                Spacer()
                                Button {
                                    HapticService.light()
                                    _ = store.refreshCurrentReading(appendToHistory: true)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                                        gaugePulse.toggle()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color("AppPrimary"))
                                        .shadow(color: Color("AppPrimary").opacity(0.4), radius: 8)
                                }
                                .buttonStyle(.plain)
                                .frame(minWidth: 44, minHeight: 44)
                            }

                            SolarGaugeView(
                                value: reading.value,
                                maxValue: 1200,
                                lowThreshold: store.thresholds.low,
                                highThreshold: store.thresholds.high
                            )
                            .scaleEffect(gaugePulse ? 1.02 : 1.0)

                            HStack {
                                thresholdChip("Low", store.thresholds.low)
                                Spacer()
                                thresholdChip("High", store.thresholds.high)
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reading Tag")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    tagChip(nil)
                                    ForEach(ReadingTag.allCases) { tag in
                                        tagChip(tag)
                                    }
                                }
                            }
                            Text("Optional note attached to the next logged reading.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }

                    if let vsYesterday, let vsWeek {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Vs Usual")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                comparisonRow("Yesterday", vsYesterday)
                                Divider().background(Color("AppTextSecondary").opacity(0.25))
                                comparisonRow("Past week", vsWeek)
                            }
                        }
                    }

                    if let bestWindow {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Best Outdoor Window")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bestWindow.label)
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(Color("AppPrimary"))
                                        Text("Avg \(Int(bestWindow.average)) W/m²")
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                    Spacer()
                                    Image(systemName: "sun.horizon.fill")
                                        .font(.title)
                                        .foregroundStyle(Color("AppAccent"))
                                }
                                HourlyForecastChart(points: hourly, highlightStart: bestWindow.startHour, highlightEnd: bestWindow.endHour)
                            }
                        }
                    }

                    Button {
                        HapticService.light()
                        showAlerts = true
                    } label: {
                        Label("Customize Alerts", systemImage: "slider.horizontal.3")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if recentValues.count > 1 {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Trend")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                MiniHistoryChart(values: recentValues)
                                Text("Last \(recentValues.count) readings")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Smart Tip")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(
                                SmartTipService.tip(
                                    value: reading.value,
                                    mode: store.activityMode,
                                    streakDays: store.stats.streakDays
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .appNavigationChrome("Today")
            .sheet(isPresented: $showAlerts) {
                CustomizeAlertsSheet()
                    .environmentObject(store)
            }
            .onAppear {
                if store.currentReading == nil {
                    _ = store.refreshCurrentReading(appendToHistory: true)
                }
            }
        }
    }

    private func modeChip(_ mode: ActivityMode) -> some View {
        let selected = store.activityMode == mode
        return Button {
            store.setActivityMode(mode)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                Text(mode.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selected
                ? AnyShapeStyle(LinearGradient(colors: [Color("AppPrimary"), Color("AppAccent")], startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(Color("AppBackground").opacity(0.55))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func tagChip(_ tag: ReadingTag?) -> some View {
        let selected = store.selectedTag == tag
        return Button {
            HapticService.light()
            store.setSelectedTag(tag)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tag?.icon ?? "tag.slash")
                Text(tag?.title ?? "None")
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func comparisonRow(_ title: String, _ result: ComparisonResult) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Image(systemName: result.isUp ? "arrow.up.right" : "arrow.down.right")
                .foregroundStyle(result.isUp ? Color.orange : Color.green)
            Text(result.headline)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func thresholdChip(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
            Text("\(Int(value)) W/m²")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color("AppBackground").opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct HourlyForecastChart: View {
    let points: [(hour: Int, value: Double)]
    let highlightStart: Int
    let highlightEnd: Int

    var body: some View {
        GeometryReader { geo in
            let maxV = max(points.map(\.value).max() ?? 1, 1)
            let spacing: CGFloat = 3
            let count = CGFloat(max(points.count, 1))
            let barWidth = max((geo.size.width - spacing * (count - 1)) / count, 3)

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    let highlighted = point.hour >= highlightStart && point.hour < highlightEnd
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(highlighted ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.35))
                            .frame(
                                width: barWidth,
                                height: max(CGFloat(point.value / maxV) * (geo.size.height - 16), 3)
                            )
                        Text("\(point.hour)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(width: barWidth)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 90)
    }
}

struct CustomizeAlertsSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var low: Double = 200
    @State private var high: Double = 800

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Low Threshold")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("\(Int(low)) W/m²")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppAccent"))
                        Slider(value: $low, in: 50...1000, step: 10)
                            .tint(Color("AppPrimary"))

                        Divider().background(Color("AppTextSecondary").opacity(0.3))

                        Text("High Threshold")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("\(Int(high)) W/m²")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppPrimary"))
                        Slider(value: $high, in: 100...1200, step: 10)
                            .tint(Color("AppAccent"))

                        Text("Markers appear on the live gauge. Threshold push alerts can be enabled in Settings.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                Spacer()
                Button {
                    store.saveThresholds(low: low, high: high)
                    dismiss()
                } label: {
                    Text("Save Alerts")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(16)
            .appNavigationChrome("Customize Alerts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                low = store.thresholds.low
                high = store.thresholds.high
            }
        }
    }
}
