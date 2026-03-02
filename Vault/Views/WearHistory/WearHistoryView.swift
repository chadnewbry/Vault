import SwiftUI
import SwiftData

struct WearHistoryView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var selectedDate = Date()
    @State private var showingLogSheet = false
    @State private var selectedTab = 0

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
            Picker("View", selection: $selectedTab) {
                Text("Calendar").tag(0)
                Text("Statistics").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            if selectedTab == 0 {
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
        .sheet(isPresented: $showingLogSheet) {
            LogWearSheet(date: selectedDate)
                .presentationDetents([.large])
        }
    }
}
