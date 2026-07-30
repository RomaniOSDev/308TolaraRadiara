import SwiftUI

struct HistoryInsightsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        NavigationStack {
            HistoryListView()
                .appNavigationChrome("History")
        }
    }
}

struct HistoryListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showFilter = false
    @State private var filterStart: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    @State private var filterEnd: Date = Date()
    @State private var filterMin: Double = 0
    @State private var filterMax: Double = 1200
    @State private var filterEnabled = false

    private var aggregates: [DailyAggregate] {
        let source: [SolarReading]
        if filterEnabled {
            source = store.filteredReadings(from: filterStart, to: filterEnd, minValue: filterMin, maxValue: filterMax)
        } else {
            source = store.readings
        }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: source) { reading -> String in
            let comps = cal.dateComponents([.year, .month, .day], from: reading.date)
            return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
        }
        return grouped.compactMap { key, values -> DailyAggregate? in
            guard let first = values.first else { return nil }
            let avg = values.map(\.value).reduce(0, +) / Double(values.count)
            return DailyAggregate(id: key, date: cal.startOfDay(for: first.date), average: avg, count: values.count)
        }
        .sorted { $0.date > $1.date }
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        Group {
            if aggregates.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color("AppPrimary"))
                        .shadow(color: Color("AppPrimary").opacity(0.45), radius: 14)
                    Text("No History Yet")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Refresh today's reading to start building your solar radiation history.")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(aggregates) { day in
                        HStack(spacing: 14) {
                            IntensitySwatch(fraction: day.average / 1200.0)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateFormatter.string(from: day.date))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Text("\(day.count) reading\(day.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                    if let tag = topTag(for: day.date) {
                                        Label(tag.title, systemImage: tag.icon)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Color("AppAccent"))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(day.average))")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color("AppPrimary"))
                                Text("avg W/m²")
                                    .font(.caption2)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color("AppSurface").opacity(0.72))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticService.light()
                    showFilter = true
                } label: {
                    Image(systemName: filterEnabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            HistoryFilterSheet(
                start: $filterStart,
                end: $filterEnd,
                minValue: $filterMin,
                maxValue: $filterMax,
                enabled: $filterEnabled
            )
        }
    }

    private func topTag(for day: Date) -> ReadingTag? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        let tags = store.readings
            .filter { $0.date >= start && $0.date < end }
            .compactMap(\.tag)
        let counted = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
        return counted.max(by: { $0.value < $1.value })?.key
    }
}

struct HistoryFilterSheet: View {
    @Binding var start: Date
    @Binding var end: Date
    @Binding var minValue: Double
    @Binding var maxValue: Double
    @Binding var enabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Date Range")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            DatePicker("From", selection: $start, displayedComponents: .date)
                                .tint(Color("AppPrimary"))
                                .foregroundStyle(Color("AppTextPrimary"))
                            DatePicker("To", selection: $end, displayedComponents: .date)
                                .tint(Color("AppPrimary"))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Value Range")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Min \(Int(minValue)) W/m²")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Slider(value: $minValue, in: 0...1100, step: 10)
                                .tint(Color("AppPrimary"))
                            Text("Max \(Int(maxValue)) W/m²")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Slider(value: $maxValue, in: 100...1200, step: 10)
                                .tint(Color("AppAccent"))
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .appNavigationChrome("Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        enabled = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        enabled = true
                        HapticService.medium()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
    }
}
