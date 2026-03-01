import SwiftUI
import Charts

struct ValueTrendChartView: View {
    let watches: [Watch]
    let dateRange: DateRange

    private var dataPoints: [(date: Date, value: Double)] {
        // Aggregate all value history entries into total collection value over time
        var allEntries: [(date: Date, watchId: UUID, value: Double)] = []
        for watch in watches {
            for entry in watch.valueHistory {
                allEntries.append((date: entry.date, watchId: watch.id, value: entry.value))
            }
            // Add purchase as initial entry if no history before it
            if let purchaseDate = watch.purchaseDate, let purchasePrice = watch.purchasePrice {
                let hasEarlier = watch.valueHistory.contains { $0.date <= purchaseDate }
                if !hasEarlier {
                    allEntries.append((date: purchaseDate, watchId: watch.id, value: purchasePrice))
                }
            }
        }

        guard !allEntries.isEmpty else { return [] }

        // Sort by date
        allEntries.sort { $0.date < $1.date }

        // Filter by date range
        let cutoff = dateRange.startDate
        let filtered = cutoff.map { c in allEntries.filter { $0.date >= c } } ?? allEntries

        // Build running total: at each point, use latest known value for each watch
        var latestValues: [UUID: Double] = [:]
        // Initialize with purchase prices for watches added before cutoff
        for watch in watches {
            if let price = watch.currentValue ?? watch.purchasePrice {
                latestValues[watch.id] = price
            }
        }

        var result: [(date: Date, value: Double)] = []
        for entry in filtered {
            latestValues[entry.watchId] = entry.value
            let total = latestValues.values.reduce(0, +)
            result.append((date: entry.date, value: total))
        }

        // Deduplicate same-day entries (keep last)
        var seen: [String: Int] = [:]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        var deduped: [(date: Date, value: Double)] = []
        for point in result {
            let key = formatter.string(from: point.date)
            if let idx = seen[key] {
                deduped[idx] = point
            } else {
                seen[key] = deduped.count
                deduped.append(point)
            }
        }

        return deduped
    }

    private var valueChange: Double? {
        guard let first = dataPoints.first, let last = dataPoints.last, first.value > 0 else { return nil }
        return ((last.value - first.value) / first.value) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Value Trend")
                    .font(.vaultHeadline)
                    .foregroundStyle(.white)
                Spacer()
                if let change = valueChange {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(change >= 0 ? .green : .red)
                }
            }

            if dataPoints.count < 2 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(Color.champagne.opacity(0.5))
                    Text("Track values over time to see trends here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart(dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(Color.champagne)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.champagne.opacity(0.25), Color.champagne.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: strideUnit)) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisTick().foregroundStyle(Color.white.opacity(0.2))
                        AxisValueLabel(format: xAxisFormat)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(abbreviatedCurrency(val))
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var strideUnit: Calendar.Component {
        switch dateRange {
        case .oneMonth: return .weekOfYear
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .quarter
        case .allTime: return .quarter
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch dateRange {
        case .oneMonth: return .dateTime.day().month(.abbreviated)
        default: return .dateTime.month(.abbreviated)
        }
    }

    private func abbreviatedCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return "$\(String(format: "%.1f", value / 1_000_000))M"
        } else if value >= 1_000 {
            return "$\(String(format: "%.0f", value / 1_000))K"
        }
        return "$\(String(format: "%.0f", value))"
    }
}
