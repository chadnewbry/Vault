import SwiftUI

struct CollectionStatsView: View {
    let watches: [Watch]

    private var mostValuable: Watch? {
        watches.max(by: { ($0.currentValue ?? 0) < ($1.currentValue ?? 0) })
    }

    private var oldest: Watch? {
        watches.filter { $0.purchaseDate != nil }
            .min(by: { $0.purchaseDate! < $1.purchaseDate! })
    }

    private var newest: Watch? {
        watches.max(by: { $0.createdAt < $1.createdAt })
    }

    private var avgValue: Double? {
        let values = watches.compactMap(\.currentValue)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // Breakdowns
    private var movementBreakdown: [(String, Int)] {
        breakdown(by: \.movementType.displayName)
    }

    private var materialBreakdown: [(String, Int)] {
        breakdown(by: \.caseMaterial.displayName)
    }

    private func breakdown(by keyPath: KeyPath<Watch, String>) -> [(String, Int)] {
        var counts: [String: Int] = [:]
        for watch in watches {
            counts[watch[keyPath: keyPath], default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collection Stats")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            // Key metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let watch = mostValuable, let value = watch.currentValue {
                    MiniStatCard(
                        icon: "crown.fill",
                        label: "Most Valuable",
                        value: watch.modelName,
                        detail: value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                    )
                }

                if let avg = avgValue {
                    MiniStatCard(
                        icon: "equal.circle.fill",
                        label: "Average Value",
                        value: avg.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                        detail: nil
                    )
                }

                if let watch = oldest {
                    MiniStatCard(
                        icon: "clock.fill",
                        label: "Oldest Piece",
                        value: watch.modelName,
                        detail: watch.purchaseDate?.formatted(.dateTime.month(.abbreviated).year()) ?? ""
                    )
                }

                if let watch = newest {
                    MiniStatCard(
                        icon: "sparkles",
                        label: "Latest Addition",
                        value: watch.modelName,
                        detail: watch.createdAt.formatted(.dateTime.month(.abbreviated).year())
                    )
                }
            }

            // Breakdowns
            if !movementBreakdown.isEmpty {
                BreakdownSection(title: "By Movement", items: movementBreakdown, total: watches.count)
            }

            if !materialBreakdown.isEmpty {
                BreakdownSection(title: "By Case Material", items: materialBreakdown, total: watches.count)
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MiniStatCard: View {
    let icon: String
    let label: String
    let value: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.champagne)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.vaultBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct BreakdownSection: View {
    let title: String
    let items: [(String, Int)]
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(item.1)")
                        .font(.subheadline)
                        .foregroundStyle(Color.champagne)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.champagne.opacity(0.3))
                            .frame(width: geo.size.width * CGFloat(item.1) / CGFloat(max(total, 1)))
                    }
                    .frame(width: 60, height: 6)
                }
            }
        }
    }
}
