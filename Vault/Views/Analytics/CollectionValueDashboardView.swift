import SwiftUI

struct CollectionValueDashboardView: View {
    let watches: [Watch]

    private var totalValue: Double {
        watches.compactMap(\.currentValue).reduce(0, +)
    }

    private var totalPurchasePrice: Double {
        watches.compactMap(\.purchasePrice).reduce(0, +)
    }

    private var totalAppreciation: Double {
        watches.compactMap(\.appreciation).reduce(0, +)
    }

    private var appreciationPercent: Double? {
        guard totalPurchasePrice > 0 else { return nil }
        return ((totalValue - totalPurchasePrice) / totalPurchasePrice) * 100
    }

    var body: some View {
        VStack(spacing: 16) {
            // Hero value
            VStack(spacing: 4) {
                Text("Collection Value")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            // Appreciation row
            if totalPurchasePrice > 0 {
                HStack(spacing: 16) {
                    AppreciationBadge(
                        label: "Total Return",
                        value: totalAppreciation,
                        percent: appreciationPercent
                    )

                    Divider()
                        .frame(height: 36)
                        .overlay(Color.white.opacity(0.1))

                    VStack(spacing: 2) {
                        Text("Invested")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(totalPurchasePrice, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
            }

            // Quick stats row
            HStack(spacing: 0) {
                QuickStat(label: "Pieces", value: "\(watches.count)", icon: "watch.analog")
                QuickStat(
                    label: "Avg Value",
                    value: watches.isEmpty ? "—" : formatCurrency(totalValue / Double(watches.count)),
                    icon: "equal.circle"
                )
                QuickStat(
                    label: "Brands",
                    value: "\(Set(watches.map(\.brand)).count)",
                    icon: "tag.fill"
                )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.vaultSurface, Color.vaultSurface.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.champagne.opacity(0.15), lineWidth: 1)
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct AppreciationBadge: View {
    let label: String
    let value: Double
    let percent: Double?

    private var isPositive: Bool { value >= 0 }
    private var color: Color { isPositive ? .green : .red }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                Text(abs(value), format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)

            if let pct = percent {
                Text("\(pct >= 0 ? "+" : "")\(String(format: "%.1f", pct))%")
                    .font(.caption2)
                    .foregroundStyle(color.opacity(0.8))
            }
        }
    }
}

struct QuickStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.champagne.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
