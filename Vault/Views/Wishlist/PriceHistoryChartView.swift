import SwiftUI
import Charts

struct PriceHistoryChartView: View {
    let watch: Watch
    var targetPrice: Double?

    private var priceHistory: [(Date, Double)] {
        ValueTrackingService.valueOverTime(for: watch)
    }

    private var yAxisMin: Double? {
        guard !priceHistory.isEmpty else { return nil }
        let values = priceHistory.map(\.1)
        let allValues = targetPrice.map { values + [$0] } ?? values
        return (allValues.min() ?? 0) * 0.9
    }

    private var yAxisMax: Double? {
        guard !priceHistory.isEmpty else { return nil }
        let values = priceHistory.map(\.1)
        let allValues = targetPrice.map { values + [$0] } ?? values
        return (allValues.max() ?? 0) * 1.1
    }

    var body: some View {
        if priceHistory.isEmpty {
            emptyState
        } else {
            chart
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(Color.champagne.opacity(0.5))
            Text("No price history yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }

    private var chart: some View {
        Chart {
            ForEach(Array(priceHistory.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Date", point.0),
                    y: .value("Price", point.1)
                )
                .foregroundStyle(Color.champagne)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.0),
                    y: .value("Price", point.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.champagne.opacity(0.3), Color.champagne.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.0),
                    y: .value("Price", point.1)
                )
                .foregroundStyle(Color.champagne)
                .symbolSize(30)
            }

            if let target = targetPrice {
                RuleMark(y: .value("Target", target))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.green.opacity(0.8))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("Target")
                            .font(.caption2)
                            .foregroundStyle(Color.green.opacity(0.8))
                    }
            }
        }
        .chartYScale(domain: (yAxisMin ?? 0)...(yAxisMax ?? 1))
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                AxisTick().foregroundStyle(Color.white.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(val, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .frame(height: 180)
    }
}
