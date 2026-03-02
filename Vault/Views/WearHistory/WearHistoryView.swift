import SwiftUI
import SwiftData

struct WearHistoryView: View {
    @Environment(DataManager.self) private var dataManager
    @Binding var selectedTab: AppTab

    @State private var selectedDate = Date()
    @State private var showingLogSheet = false
    @State private var selectedTabSegment = 0

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var allWearLogs: [WearLog] {
        let descriptor = FetchDescriptor<WearLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? dataManager.modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTabSegment) {
                Text("Calendar").tag(0)
                Text("Statistics").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            if selectedTabSegment == 0 {
                WearCalendarView(
                    selectedDate: $selectedDate,
                    showingLogSheet: $showingLogSheet,
                    wearLogs: allWearLogs,
                    watches: watches
                )
            } else {
                WearStatisticsView(
                    wearLogs: allWearLogs,
                    watches: watches
                )
            }
        }
        .navigationTitle("Wear History")
        .background(Color.vaultBackground)
        .navigationDestination(for: UUID.self) { watchID in
            if let watch = dataManager.fetchWatches().first(where: { $0.id == watchID }) {
                WatchDetailView(watch: watch, selectedTab: $selectedTab)
                    .environment(dataManager)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedTab = .collection
                } label: {
                    Image(systemName: "watch.analog")
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogWearSheet(date: selectedDate)
                .presentationDetents([.large])
        }
    }
}
