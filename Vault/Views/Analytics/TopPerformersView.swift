import SwiftUI

struct TopPerformersView: View {
    let watches: [Watch]

    private var watchesWithAppreciation: [(watch: Watch, appreciation: Double, percent: Double)] {
        watches.compactMap { watch in
            guard let appreciation = watch.appreciation, let percent = watch.appreciationPercentage else { return nil }
            return (watch: watch, appreciation: appreciation, percent: percent)
        }
        .sorted { $0.percent > $1.percent }
    }

    private var topGainers: [(watch: Watch, appreciation: Double, percent: Double)] {
        Array(watchesWithAppreciation.filter { $0.percent > 0 }.prefix(3))
    }

    private var topLosers: [(watch: Watch, appreciation: Double, percent: Double)] {
        Array(watchesWithAppreciation.filter { $0.percent < 0 }.suffix(3).reversed())
    }

    var body: some View {
        if !watchesWithAppreciation.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance")
                    .font(.vaultHeadline)
                    .foregroundStyle(.white)

                if !topGainers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Top Gainers", systemImage: "arrow.up.right.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        ForEach(topGainers, id: \.watch.id) { item in
                            PerformerRow(watch: item.watch, appreciation: item.appreciation, percent: item.percent)
                        }
                    }
                }

                if !topLosers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Declining", systemImage: "arrow.down.right.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        ForEach(topLosers, id: \.watch.id) { item in
                            PerformerRow(watch: item.watch, appreciation: item.appreciation, percent: item.percent)
                        }
                    }
                }
            }
            .padding()
            .background(Color.vaultSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct PerformerRow: View {
    let watch: Watch
    let appreciation: Double
    let percent: Double

    private var isPositive: Bool { appreciation >= 0 }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(watch.brand) \(watch.modelName)")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                if let current = watch.currentValue {
                    Text(current, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isPositive ? "+" : "")\(String(format: "%.1f", percent))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isPositive ? .green : .red)
                Text("\(isPositive ? "+" : "")\(Int(appreciation).formatted(.currency(code: "USD").precision(.fractionLength(0))))")
                    .font(.caption)
                    .foregroundStyle(isPositive ? .green.opacity(0.7) : .red.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}
