import SwiftUI
import Charts

struct BrandBreakdownChartView: View {
    let watches: [Watch]

    private var brandData: [(brand: String, value: Double, count: Int)] {
        var grouped: [String: (value: Double, count: Int)] = [:]
        for watch in watches {
            let val = watch.currentValue ?? watch.purchasePrice ?? 0
            let existing = grouped[watch.brand, default: (value: 0, count: 0)]
            grouped[watch.brand] = (value: existing.value + val, count: existing.count + 1)
        }
        return grouped.map { (brand: $0.key, value: $0.value.value, count: $0.value.count) }
            .sorted { $0.value > $1.value }
    }

    private var totalValue: Double {
        brandData.reduce(0) { $0 + $1.value }
    }

    private let chartColors: [Color] = [
        .champagne, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Brand")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            if brandData.isEmpty {
                Text("No value data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 16) {
                    Chart(brandData, id: \.brand) { item in
                        SectorMark(
                            angle: .value("Value", item.value),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(colorFor(item.brand))
                        .cornerRadius(4)
                    }
                    .frame(width: 140, height: 140)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(brandData.prefix(6).enumerated()), id: \.element.brand) { idx, item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(chartColors[idx % chartColors.count])
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(item.brand)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                    Text("\(item.count) piece\(item.count == 1 ? "" : "s") · \(percentString(item.value))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if brandData.count > 6 {
                            Text("+\(brandData.count - 6) more")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func colorFor(_ brand: String) -> Color {
        guard let idx = brandData.firstIndex(where: { $0.brand == brand }) else { return .gray }
        return chartColors[idx % chartColors.count]
    }

    private func percentString(_ value: Double) -> String {
        guard totalValue > 0 else { return "0" }
        return String(format: "%.0f", (value / totalValue) * 100)
    }
}
