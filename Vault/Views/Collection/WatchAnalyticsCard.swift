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

    private var totalCostOfOwnership: Double? {
        guard let purchase = watch.purchasePrice else { return nil }
        let serviceCosts = watch.serviceRecords.compactMap(\.cost).reduce(0, +)
        let appreciation = watch.appreciation ?? 0
        return purchase + serviceCosts - appreciation
    }

    private var roiPercentage: Double? {
        guard let purchase = watch.purchasePrice, purchase > 0 else { return nil }
        let appreciation = watch.appreciation ?? 0
        let serviceCosts = watch.serviceRecords.compactMap(\.cost).reduce(0, +)
        return ((appreciation - serviceCosts) / purchase) * 100
    }

    private var currentWearStreak: Int {
        let calendar = Calendar.current
        let sortedDates = Set(watch.wearLogs.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        guard sortedDates.first == today || sortedDates.first == calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var streak = 0
        var expectedDate = sortedDates.first!
        for date in sortedDates {
            if date == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    private var longestWearStreak: Int {
        let calendar = Calendar.current
        let sortedDates = Set(watch.wearLogs.map { calendar.startOfDay(for: $0.date) }).sorted()
        guard sortedDates.count > 1 else { return sortedDates.count }

        var maxStreak = 1
        var currentStreak = 1
        for i in 1..<sortedDates.count {
            if calendar.date(byAdding: .day, value: 1, to: sortedDates[i - 1]) == sortedDates[i] {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        return maxStreak
    }

    private var projectedAnnualWears: Int {
        guard ownershipDays > 0, watch.wearCount > 0 else { return 0 }
        return Int(round(Double(watch.wearCount) / Double(ownershipDays) * 365.25))
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

    private var insights: [WatchInsight] {
        var result: [WatchInsight] = []

        if let cpw = costPerWear {
            if cpw < 50 {
                result.append(WatchInsight(icon: "star.fill", text: "Excellent value — under $50 per wear", tone: .positive))
            } else if cpw > 500 {
                result.append(WatchInsight(icon: "arrow.up.circle", text: "Wear more to bring down your \(abbreviatedCurrency(cpw)) cost per wear", tone: .suggestion))
            }
        }

        if let pct = watch.appreciationPercentage {
            if pct > 10 {
                result.append(WatchInsight(icon: "chart.line.uptrend.xyaxis", text: "Up \(String(format: "%.1f", pct))% since purchase — strong performer", tone: .positive))
            } else if pct < -10 {
                result.append(WatchInsight(icon: "chart.line.downtrend.xyaxis", text: "Down \(String(format: "%.1f", abs(pct)))% — typical for recent purchases", tone: .neutral))
            }
        }

        if wearsPerMonth > 15 {
            result.append(WatchInsight(icon: "flame.fill", text: "Your most active rotation piece", tone: .positive))
        } else if ownershipDays > 90 && wearsPerMonth < 1 {
            result.append(WatchInsight(icon: "moon.zzz.fill", text: "Rarely worn — consider if it belongs in rotation", tone: .suggestion))
        }

        if currentWearStreak >= 3 {
            result.append(WatchInsight(icon: "bolt.fill", text: "\(currentWearStreak)-day streak — you're on a roll!", tone: .positive))
        }

        if watch.movementType == .automatic || watch.movementType == .manual {
            let lastService = watch.serviceRecords.sorted(by: { $0.serviceDate > $1.serviceDate }).first
            if let lastService {
                let daysSince = Calendar.current.dateComponents([.day], from: lastService.serviceDate, to: Date()).day ?? 0
                if daysSince > 365 * 5 {
                    result.append(WatchInsight(icon: "wrench.adjustable", text: "Over 5 years since last service — mechanical watches need regular care", tone: .suggestion))
                }
            } else if ownershipDays > 365 * 3 {
                result.append(WatchInsight(icon: "wrench.adjustable", text: "No service records — consider a checkup for your mechanical movement", tone: .suggestion))
            }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.vaultHeadline)
                .foregroundStyle(.white)

            statsGrid

            if !insights.isEmpty {
                insightsSection
            }

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

            if projectedAnnualWears > 0 {
                statCell(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Projected / Year",
                    value: "\(projectedAnnualWears)"
                )
            }

            if let roi = roiPercentage {
                statCell(
                    icon: "percent",
                    label: "Net ROI",
                    value: "\(roi >= 0 ? "+" : "")\(String(format: "%.1f", roi))%",
                    valueColor: roi >= 0 ? .green : .red
                )
            }

            if let tco = totalCostOfOwnership {
                statCell(
                    icon: "banknote",
                    label: "True Cost",
                    value: tco < 1000
                        ? tco.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                        : abbreviatedCurrency(tco)
                )
            }

            if longestWearStreak > 1 {
                statCell(
                    icon: "flame.fill",
                    label: "Best Streak",
                    value: "\(longestWearStreak) days"
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

    private func statCell(icon: String, label: String, value: String, valueColor: Color = .white) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.champagne)
            Text(value)
                .font(.headline)
                .foregroundStyle(valueColor)
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

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 6) {
                ForEach(insights.prefix(3), id: \.text) { insight in
                    HStack(spacing: 10) {
                        Image(systemName: insight.icon)
                            .font(.caption)
                            .foregroundStyle(insight.tone.color)
                            .frame(width: 20)
                        Text(insight.text)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(insight.tone.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
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

// MARK: - Watch Insight Model

private struct WatchInsight {
    let icon: String
    let text: String
    let tone: InsightTone

    enum InsightTone {
        case positive, neutral, suggestion

        var color: Color {
            switch self {
            case .positive: .green
            case .neutral: Color.champagne
            case .suggestion: .orange
            }
        }
    }
}
