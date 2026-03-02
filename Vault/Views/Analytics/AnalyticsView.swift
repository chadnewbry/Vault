import SwiftUI
import Charts

struct AnalyticsView: View {
    @Binding var selectedTab: AppTab
    @State private var dataManager = DataManager.shared
    @State private var selectedRange: DateRange = .sixMonths
    @State private var showExportSheet = false
    @State private var exportImage: UIImage?

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    var body: some View {
        NavigationStack {
            Group {
                if watches.isEmpty {
                    emptyState
                } else {
                    dashboard
                }
            }
            .navigationTitle("Analytics")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedTab = .collection
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "watch.analog")
                            Text("Collection")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.champagne)
                    }
                }
                if !watches.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                exportSnapshot()
                            } label: {
                                Label("Share Snapshot", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.champagne)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let image = exportImage {
                    ShareSheetView(image: image)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.champagne.opacity(0.5))
            Text("Analytics")
                .font(.vaultTitle)
                .foregroundStyle(.white)
            Text("Add watches to your collection to see value trends, breakdowns, and insights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                selectedTab = .collection
            } label: {
                Label("Go to Collection", systemImage: "watch.analog")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.champagne)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.vaultBackground)
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 20) {
                dateRangePicker
                CollectionValueDashboardView(watches: watches)
                ValueTrendChartView(watches: watches, dateRange: selectedRange)
                BrandBreakdownChartView(watches: watches)
                TopPerformersView(watches: watches)
                CollectionStatsView(watches: watches)
                WearAnalyticsView(watches: watches, dateRange: selectedRange)
                ComparisonView(watches: watches)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .background(Color.vaultBackground)
    }

    private var dateRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateRange.allCases) { range in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedRange = range
                        }
                    } label: {
                        Text(range.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedRange == range ? Color.champagne : Color.vaultSurface)
                            .foregroundStyle(selectedRange == range ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func exportSnapshot() {
        let renderer = ImageRenderer(
            content: AnalyticsExportView(watches: watches)
                .frame(width: 390)
        )
        renderer.scale = 3
        if let image = renderer.uiImage {
            exportImage = image
            showExportSheet = true
        }
    }
}

enum DateRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case allTime = "All"

    var id: String { rawValue }
    var label: String { rawValue }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
        case .oneYear: return calendar.date(byAdding: .year, value: -1, to: Date())
        case .allTime: return nil
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
