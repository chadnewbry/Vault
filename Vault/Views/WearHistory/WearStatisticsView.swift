import SwiftUI
import Charts

struct WearStatisticsView: View {
    let wearLogs: [WearLog]
    let watches: [Watch]

    private var wearDistribution: [(watch: Watch, count: Int)] {
        var counts: [UUID: Int] = [:]
        for log in wearLogs {
            if let id = log.watch?.id {
                counts[id, default: 0] += 1
            }
        }
        return watches.compactMap { watch in
            guard let count = counts[watch.id], count > 0 else { return nil }
            return (watch: watch, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    private var neglectedWatches: [Watch] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return watches.filter { watch in
            guard let lastWorn = watch.lastWorn else { return true }
            return lastWorn < thirtyDaysAgo
        }
    }

    private var mostWorn: (watch: Watch, count: Int)? {
        wearDistribution.first
    }

    private var leastWorn: (watch: Watch, count: Int)? {
        wearDistribution.last
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if wearLogs.isEmpty {
                    emptyState
                } else {
                    summaryCards
                    distributionChart
                    topWatches
                    if !neglectedWatches.isEmpty {
                        neglectedSection
                    }
                    costPerWearSection
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundStyle(Color.champagne.opacity(0.5))
            Text("No wear data yet")
                .font(.vaultHeadline)
                .foregroundStyle(.white)
            Text("Start logging which watches you wear to see beautiful statistics here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total Wears", value: "\(wearLogs.count)", icon: "calendar")
            StatCard(title: "Watches Worn", value: "\(wearDistribution.count)", icon: "watch.analog")
            StatCard(
                title: "This Month",
                value: "\(thisMonthCount)",
                icon: "calendar.badge.clock"
            )
        }
    }

    private var thisMonthCount: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return wearLogs.filter { $0.date >= startOfMonth }.count
    }

    // MARK: - Distribution Chart

    private var distributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wear Distribution")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            Chart(wearDistribution, id: \.watch.id) { item in
                SectorMark(
                    angle: .value("Wears", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(colorForWatch(item.watch))
                .cornerRadius(4)
            }
            .frame(height: 200)

            // Legend - tappable to navigate to watch detail
            VStack(alignment: .leading, spacing: 6) {
                ForEach(wearDistribution, id: \.watch.id) { item in
                    NavigationLink(value: item.watch.id) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForWatch(item.watch))
                                .frame(width: 10, height: 10)
                            Text("\(item.watch.brand) \(item.watch.modelName)")
                                .font(.caption)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(item.count) (\(percentage(item.count))%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Top Watches

    private var topWatches: some View {
        HStack(spacing: 12) {
            if let most = mostWorn {
                NavigationLink(value: most.watch.id) {
                    WatchStatCard(
                        title: "Most Worn",
                        watch: most.watch,
                        detail: "\(most.count) times",
                        icon: "crown.fill",
                        accentColor: Color.champagne
                    )
                }
                .buttonStyle(.plain)
            }
            if let least = leastWorn, wearDistribution.count > 1 {
                NavigationLink(value: least.watch.id) {
                    WatchStatCard(
                        title: "Least Worn",
                        watch: least.watch,
                        detail: "\(least.count) times",
                        icon: "arrow.down.circle.fill",
                        accentColor: .secondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Neglected Section

    private var neglectedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Neglected Pieces")
                    .font(.vaultHeadline)
                    .foregroundStyle(.white)
            }

            Text("These watches haven't been worn in over 30 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(neglectedWatches) { watch in
                NavigationLink(value: watch.id) {
                    NeglectedWatchRow(watch: watch)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Cost Per Wear

    private var costPerWearSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Per Wear")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            let items = costPerWearData
            if items.isEmpty {
                Text("Add purchase prices to see cost per wear analysis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.watch.id) { item in
                    NavigationLink(value: item.watch.id) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.watch.brand) \(item.watch.modelName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Text("\(item.wears) wears")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.costPerWear, format: .currency(code: "USD"))
                                .font(.vaultHeadline)
                                .foregroundStyle(Color.champagne)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var costPerWearData: [(watch: Watch, wears: Int, costPerWear: Double)] {
        wearDistribution.compactMap { item in
            guard let value = item.watch.currentValue ?? item.watch.purchasePrice,
                  item.count > 0 else { return nil }
            return (watch: item.watch, wears: item.count, costPerWear: value / Double(item.count))
        }
        .sorted { $0.costPerWear < $1.costPerWear }
    }

    // MARK: - Helpers

    private let chartColors: [Color] = [
        .champagne, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal
    ]

    private func colorForWatch(_ watch: Watch) -> Color {
        guard let index = watches.firstIndex(where: { $0.id == watch.id }) else { return .gray }
        return chartColors[index % chartColors.count]
    }

    private func percentage(_ count: Int) -> Int {
        guard !wearLogs.isEmpty else { return 0 }
        let total = wearDistribution.reduce(0) { $0 + $1.count }
        return Int(round(Double(count) / Double(total) * 100))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.champagne)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Watch Stat Card

struct WatchStatCard: View {
    let title: String
    let watch: Watch
    let detail: String
    let icon: String
    let accentColor: Color

    @State private var photo: UIImage?

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)

            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "watch.analog")
                        .font(.title3)
                        .foregroundStyle(Color.champagne.opacity(0.5))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(watch.modelName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            if let fileName = watch.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}

// MARK: - Neglected Watch Row

struct NeglectedWatchRow: View {
    let watch: Watch

    @State private var photo: UIImage?

    private var daysSinceWorn: Int? {
        guard let lastWorn = watch.lastWorn else { return nil }
        return Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "watch.analog")
                        .font(.caption)
                        .foregroundStyle(Color.champagne.opacity(0.5))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(watch.brand) \(watch.modelName)")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                if let days = daysSinceWorn {
                    Text("\(days) days since last worn")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("Never worn")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            if let fileName = watch.photoFileNames.first {
                photo = await PhotoStorageService.shared.loadPhoto(named: fileName)
            }
        }
    }
}
