import SwiftUI

struct AnalyticsExportView: View {
    let watches: [Watch]

    private var totalValue: Double {
        watches.compactMap(\.currentValue).reduce(0, +)
    }

    private var totalAppreciation: Double {
        watches.compactMap(\.appreciation).reduce(0, +)
    }

    private var topBrands: [(String, Int)] {
        var counts: [String: Int] = [:]
        for w in watches { counts[w.brand, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.title)
                    .foregroundStyle(Color.champagne)
                Text("My Collection")
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(.white)
                Text("Vault")
                    .font(.caption)
                    .foregroundStyle(Color.champagne)
                    .tracking(3)
                    .textCase(.uppercase)
            }

            // Value
            VStack(spacing: 4) {
                Text(totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                if totalAppreciation != 0 {
                    Text("\(totalAppreciation >= 0 ? "↑" : "↓") \(abs(totalAppreciation), format: .currency(code: "USD").precision(.fractionLength(0)))")
                        .font(.subheadline)
                        .foregroundStyle(totalAppreciation >= 0 ? .green : .red)
                }
            }

            // Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(watches.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Pieces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(Set(watches.map(\.brand)).count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Brands")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Top brands
            if !topBrands.isEmpty {
                VStack(spacing: 6) {
                    ForEach(topBrands.prefix(3), id: \.0) { brand, count in
                        HStack {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline)
                                .foregroundStyle(Color.champagne)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Text(Date.now, format: .dateTime.month(.wide).year())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(
            LinearGradient(
                colors: [Color.vaultBackground, Color(red: 0.1, green: 0.1, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
