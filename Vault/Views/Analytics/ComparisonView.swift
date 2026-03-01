import SwiftUI
import Charts

struct ComparisonView: View {
    let watches: [Watch]
    @State private var selectedWatchIds: Set<UUID> = []
    @State private var showPicker = false

    private var selectedWatches: [Watch] {
        watches.filter { selectedWatchIds.contains($0.id) }
    }

    private let chartColors: [Color] = [
        .champagne, .blue, .green, .orange, .purple, .pink
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compare")
                    .font(.vaultHeadline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showPicker.toggle()
                } label: {
                    Label(
                        selectedWatches.isEmpty ? "Select Watches" : "\(selectedWatches.count) selected",
                        systemImage: "plus.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.champagne)
                }
            }

            if showPicker {
                watchPicker
            }

            if selectedWatches.count >= 2 {
                comparisonChart
                comparisonTable
            } else if !selectedWatches.isEmpty {
                Text("Select at least 2 watches to compare")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                Text("Compare value trends between watches side by side")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
        .padding()
        .background(Color.vaultSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var watchPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(watches) { watch in
                    let isSelected = selectedWatchIds.contains(watch.id)
                    Button {
                        withAnimation {
                            if isSelected {
                                selectedWatchIds.remove(watch.id)
                            } else if selectedWatchIds.count < 6 {
                                selectedWatchIds.insert(watch.id)
                            }
                        }
                    } label: {
                        Text("\(watch.brand) \(watch.modelName)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.champagne : Color.vaultBackground)
                            .foregroundStyle(isSelected ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var comparisonChart: some View {
        Chart {
            ForEach(Array(selectedWatches.enumerated()), id: \.element.id) { idx, watch in
                let history = ValueTrackingService.valueOverTime(for: watch)
                ForEach(Array(history.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.0),
                        y: .value("Value", point.1),
                        series: .value("Watch", watch.modelName)
                    )
                    .foregroundStyle(chartColors[idx % chartColors.count])
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisTick().foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(val, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 200)
    }

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            ForEach(Array(selectedWatches.enumerated()), id: \.element.id) { idx, watch in
                HStack {
                    Circle()
                        .fill(chartColors[idx % chartColors.count])
                        .frame(width: 8, height: 8)
                    Text(watch.modelName)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    if let current = watch.currentValue {
                        Text(current, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    if let pct = watch.appreciationPercentage {
                        Text("\(pct >= 0 ? "+" : "")\(String(format: "%.1f", pct))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(pct >= 0 ? .green : .red)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.vertical, 6)
                if idx < selectedWatches.count - 1 {
                    Divider().overlay(Color.white.opacity(0.06))
                }
            }
        }
    }
}
