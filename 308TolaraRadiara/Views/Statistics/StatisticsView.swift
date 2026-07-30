import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var period = 1
    @State private var didRecord = false

    private var chartPoints: [(label: String, value: Double)] {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case 0:
            return (0..<8).compactMap { offset -> (String, Double)? in
                guard let date = cal.date(byAdding: .hour, value: -offset, to: now) else { return nil }
                let hour = cal.component(.hour, from: date)
                let matching = store.readings.filter {
                    abs($0.date.timeIntervalSince(date)) < 1800
                }
                let value = matching.isEmpty
                    ? SolarSimulator.radiation(for: date)
                    : matching.map(\.value).reduce(0, +) / Double(matching.count)
                return ("\(hour)h", value)
            }.reversed()
        case 1:
            return (0..<7).compactMap { offset -> (String, Double)? in
                guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
                let start = cal.startOfDay(for: day)
                let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
                let dayReadings = store.readings.filter { $0.date >= start && $0.date < end }
                let value = dayReadings.isEmpty
                    ? SolarSimulator.radiation(for: day)
                    : dayReadings.map(\.value).reduce(0, +) / Double(dayReadings.count)
                let label = cal.shortWeekdaySymbols[cal.component(.weekday, from: day) - 1]
                return (String(label.prefix(2)), value)
            }.reversed()
        default:
            return (0..<6).compactMap { offset -> (String, Double)? in
                guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now) else { return nil }
                let comps = cal.dateComponents([.year, .month], from: monthDate)
                let monthReadings = store.readings.filter {
                    let c = cal.dateComponents([.year, .month], from: $0.date)
                    return c.year == comps.year && c.month == comps.month
                }
                let value = monthReadings.isEmpty
                    ? SolarSimulator.radiation(for: monthDate) * 0.85
                    : monthReadings.map(\.value).reduce(0, +) / Double(monthReadings.count)
                let label = cal.shortMonthSymbols[(comps.month ?? 1) - 1]
                return (String(label.prefix(3)), value)
            }.reversed()
        }
    }

    private var averages: (avg: Double, peak: Double, min: Double) {
        let values = chartPoints.map(\.value)
        guard !values.isEmpty else { return (0, 0, 0) }
        return (
            values.reduce(0, +) / Double(values.count),
            values.max() ?? 0,
            values.min() ?? 0
        )
    }

    private var intensityBuckets: [(title: String, count: Int, color: Color)] {
        let readings = store.readings
        let low = readings.filter { $0.value < 200 }.count
        let moderate = readings.filter { $0.value >= 200 && $0.value < 500 }.count
        let high = readings.filter { $0.value >= 500 && $0.value < 800 }.count
        let extreme = readings.filter { $0.value >= 800 }.count
        return [
            ("Low", low, .green),
            ("Moderate", moderate, .yellow),
            ("High", high, .orange),
            ("Extreme", extreme, .red)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        HStack(spacing: 0) {
                            summaryCell("Readings", "\(store.stats.itemsCreated)")
                            summaryCell("Streak", "\(store.stats.streakDays)d")
                            summaryCell("Sessions", "\(store.stats.sessionsCompleted)")
                        }
                    }

                    if let vsYesterday = store.comparison(againstDays: 1),
                       let vsWeek = store.comparison(againstDays: 7) {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Compared to Usual")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                comparisonLine("Yesterday", vsYesterday)
                                Divider().background(Color("AppTextSecondary").opacity(0.25))
                                comparisonLine("Past week", vsWeek)
                            }
                        }
                    }

                    Picker("Period", selection: $period) {
                        Text("Daily").tag(0)
                        Text("Weekly").tag(1)
                        Text("Monthly").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: period) { _ in
                        HapticService.light()
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Radiation Trend")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            InsightLineChart(points: chartPoints)
                            HStack(spacing: 0) {
                                ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                                    Text(point.label)
                                        .font(.caption2)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                        .frame(maxWidth: .infinity)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Period Bars")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            StatsBarChart(points: chartPoints)
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            statRow("Average", "\(Int(averages.avg)) W/m²", Color("AppAccent"))
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            statRow("Peak", "\(Int(averages.peak)) W/m²", Color("AppPrimary"))
                            Divider().background(Color("AppTextSecondary").opacity(0.25))
                            statRow("Lowest", "\(Int(averages.min)) W/m²", Color("AppTextSecondary"))
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Intensity Mix")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            if store.readings.isEmpty {
                                Text("Log readings to see distribution.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            } else {
                                IntensityDistributionChart(buckets: intensityBuckets)
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .appNavigationChrome("Statistics")
            .onAppear {
                guard !didRecord else { return }
                didRecord = true
                store.recordInsightSession()
            }
        }
    }

    private func summaryCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func comparisonLine(_ title: String, _ result: ComparisonResult) -> some View {
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

    private func statRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 10)
    }
}

struct StatsBarChart: View {
    let points: [(label: String, value: Double)]

    var body: some View {
        GeometryReader { geo in
            let maxV = max(points.map(\.value).max() ?? 1, 1)
            let spacing: CGFloat = 6
            let count = CGFloat(max(points.count, 1))
            let barWidth = max((geo.size.width - spacing * (count - 1)) / count, 4)

            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppAccent"), Color("AppPrimary")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: max(CGFloat(point.value / maxV) * (geo.size.height - 18), 4)
                            )
                        Text(point.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: barWidth)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 150)
    }
}

struct IntensityDistributionChart: View {
    let buckets: [(title: String, count: Int, color: Color)]

    private var total: Int {
        max(buckets.map(\.count).reduce(0, +), 1)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bucket.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        Text("\(bucket.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color("AppBackground").opacity(0.55))
                            Capsule()
                                .fill(bucket.color.opacity(0.85))
                                .frame(width: max(geo.size.width * CGFloat(bucket.count) / CGFloat(total), bucket.count > 0 ? 8 : 0))
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
    }
}
