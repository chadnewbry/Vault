import SwiftUI
import Charts

struct WatchAnalyticsCard: View {
    let watch: Watch

    // MARK: - Computed Properties

    private var ownershipDays: Int {
        guard let purchase = watch.purchaseDate else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: purchase, to: Date()).day ?? 0)
    }

    private var costPerWear: Double? {
        let value = watch.currentValue ?? watch.purchasePrice
        guard let v = value, watch.wearCount > 0 else { return nil }
        return v / Double(watch.wearCount)
    }

    private var wearsPerMonth: Double {
        guard watch.wearCount > 0 else { return 0 }
        let months = max(1.0, Double(ownershipDays) / 30.44)
        return Double(watch.wearCount) / months
    }

    private var valuePerDay: Double? {
        guard let appreciation = watch.appreciation, ownershipDays > 0 else { return nil }
        return appreciation / Double(ownershipDays)
    }

    private var monthlyWearData: [(month: Date, count: Int)] {
        let calendar = Calendar.current
        var buckets: [Date: Int] = [:]
        for log in watch.wearLogs {
            let comps = calendar.dateComponents([.year, .month], from: log.date)
            if let monthStart = calendar.date(from: comps) {
                buckets[monthStart, default: 0] += 1
            }
        }
        return buckets.sorted { $0.key < $1.key }.map { (month: $0.key, count: $0.value) }
    }

    private var valueTrendData: [(date: Date, value: Double)] {
        var points: [(date: Date, value: Double)] = []
        if let purchaseDate = watch.purchaseDate, let purchasePrice = watch.purchasePrice {
            points.append((date: purchaseDate, value: purchasePrice))
        }
        for entry in watch.valueHistory.sorted(by: { $0.date < $1.date }) {
            points.append((date: entry.date, value: entry.value))
        }
        if let current = watch.currentValue {
            let lastHistoryDate = points.last?.date ?? Date()
            if Calendar.current.startOfDay(for: lastHistoryDate) != Calendar.current.startOfDay(for: Date()) {
                points.append((date: Date(), value: current))
            }
        }
        return points
    }

    private var dayOfWeekData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var counts = Array(repeating: 0, count: 7)
        for log in watch.wearLogs {
            let weekday = calendar.component(.weekday, from: log.date) - 1
            counts[weekday] += 1
        }
        return dayNames.enumerated().map { (day: $0.element, count: counts[$0.offset]) }
    }

    private var favoriteDay: String? {
        dayOfWeekData.max(by: { $0.count < $1.count }).flatMap { $0.count > 0 ? $0.day : nil }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            statsGrid

            if valueTrendData.count >= 2 {
                valueTrendSection
            }

            if !monthlyWearData.isEmpty {
                wearFrequencySection
            }

            if watch.wearCount > 0 {
                dayOfWeekSection
            }
        }
        .padding(20)
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let cpw = costPerWear {
                statCell(
                    icon: "dollarsign.arrow.circlepath",
                    label: "Cost Per Wear",
                    value: cpw < 1000
                        ? cpw.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                        : abbreviatedCurrency(cpw)
                )
            }

            statCell(
                icon: "calendar.badge.clock",
                label: "Wears / Month",
                value: String(format: "%.1f", wearsPerMonth)
            )

            if ownershipDays > 0 {
                statCell(
                    icon: "clock.arrow.circlepath",
                    label: "Days Owned",
                    value: "\(ownershipDays)"
                )
            }

            if let vpd = valuePerDay {
                statCell(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Value / Day",
                    value: "\(vpd >= 0 ? "+" : "")\(vpd.formatted(.currency(code: "USD").precision(.fractionLength(2))))"
                )
            }

            if let day = favoriteDay {
                statCell(
                    icon: "star.fill",
                    label: "Favorite Day",
                    value: day
                )
            }

            if !watch.serviceRecords.isEmpty {
                let totalCost = watch.serviceRecords.compactMap(\.cost).reduce(0, +)
                statCell(
                    icon: "wrench.and.screwdriver",
                    label: "Service Cost",
                    value: totalCost.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                )
            }
        }
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.champagne)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.champagne.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Value Trend

    private var valueTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Value Over Time")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Chart(valueTrendData, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(Color.champagne)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.champagne.opacity(0.2), Color.champagne.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(abbreviatedCurrency(val))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 160)
        }
    }

    // MARK: - Wear Frequency

    private var wearFrequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Wear Frequency")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Chart(monthlyWearData, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Wears", item.count)
                )
                .foregroundStyle(Color.champagne.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
            .frame(height: 120)
        }
    }

    // MARK: - Day of Week

    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wear by Day of Week")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Chart(dayOfWeekData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.champagne.opacity(0.7).gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
            .frame(height: 100)
        }
    }

    // MARK: - Helpers

    private func abbreviatedCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return "$\(String(format: "%.1f", value / 1_000_000))M"
        } else if value >= 1_000 {
            return "$\(String(format: "%.1f", value / 1_000))K"
        }
        return "$\(String(format: "%.0f", value))"
    }
}
