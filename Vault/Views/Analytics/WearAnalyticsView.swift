import SwiftUI
import Charts

struct WearAnalyticsView: View {
    let watches: [Watch]
    let dateRange: DateRange
    var onLogWear: ((Watch?) -> Void)?

    private var allLogs: [WearLog] {
        watches.flatMap(\.wearLogs)
    }

    private var filteredLogs: [WearLog] {
        guard let cutoff = dateRange.startDate else { return allLogs }
        return allLogs.filter { $0.date >= cutoff }
    }

    // Heatmap: day -> count
    private var heatmapData: [Date: Int] {
        let calendar = Calendar.current
        var data: [Date: Int] = [:]
        for log in filteredLogs {
            let day = calendar.startOfDay(for: log.date)
            data[day, default: 0] += 1
        }
        return data
    }

    private var costPerWear: [(watch: Watch, cost: Double, wears: Int)] {
        watches.compactMap { watch in
            let value = watch.currentValue ?? watch.purchasePrice
            guard let v = value, !watch.wearLogs.isEmpty else { return nil }
            return (watch: watch, cost: v / Double(watch.wearLogs.count), wears: watch.wearLogs.count)
        }
        .sorted { $0.cost < $1.cost }
    }

    var body: some View {
        if !allLogs.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Wear Analytics")
                        .font(.vaultHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        onLogWear?(nil)
                    } label: {
                        Label("Log Wear", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.champagne)
                    }
                }

                // Heatmap calendar
                WearHeatmapView(data: heatmapData, dateRange: dateRange)

                // Cost per wear ranking
                if !costPerWear.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best Value (Cost Per Wear)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        ForEach(costPerWear.prefix(5), id: \.watch.id) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(item.watch.brand) \(item.watch.modelName)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Text("\(item.wears) wears")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(item.cost, format: .currency(code: "USD").precision(.fractionLength(0)))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.champagne)
                                Text("/wear")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Quick wear log shortcuts
                quickWearSection
            }
            .padding()
            .background(Color.vaultSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var quickWearSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Log")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(watches.prefix(6)) { watch in
                        Button {
                            onLogWear?(watch)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "watch.analog")
                                    .font(.title3)
                                    .foregroundStyle(Color.champagne)
                                    .frame(width: 44, height: 44)
                                    .background(Color.champagne.opacity(0.15))
                                    .clipShape(Circle())

                                Text(watch.modelName)
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .frame(width: 64)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Wear Heatmap

struct WearHeatmapView: View {
    let data: [Date: Int]
    let dateRange: DateRange

    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = dateRange.startDate.map { calendar.startOfDay(for: $0) }
            ?? calendar.date(byAdding: .month, value: -3, to: end)!

        var weeks: [[Date?]] = []
        var current = start

        // Align to start of week
        let weekday = calendar.component(.weekday, from: current)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: current)!
        current = startOfWeek

        while current <= end {
            var week: [Date?] = []
            for _ in 0..<7 {
                if current >= start && current <= end {
                    week.append(current)
                } else {
                    week.append(nil)
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            weeks.append(week)
        }
        return weeks
    }

    private var maxCount: Int {
        data.values.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Wear Calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { dayIdx in
                                if let date = week[safe: dayIdx] ?? nil {
                                    let count = data[date] ?? 0
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(heatColor(count: count))
                                        .frame(width: 12, height: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 100)

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(level: Double(level) / 4.0))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func heatColor(count: Int) -> Color {
        guard count > 0, maxCount > 0 else { return Color.white.opacity(0.05) }
        let intensity = Double(count) / Double(maxCount)
        return heatColor(level: intensity)
    }

    private func heatColor(level: Double) -> Color {
        if level <= 0 { return Color.white.opacity(0.05) }
        return Color.champagne.opacity(0.2 + (level * 0.8))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
