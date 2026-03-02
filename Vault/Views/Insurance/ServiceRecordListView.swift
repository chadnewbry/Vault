import SwiftUI

struct ServiceRecordListView: View {
    @Environment(DataManager.self) private var dataManager
    var filterWatch: Watch? = nil

    @State private var showingAddRecord = false

    private var watches: [Watch] {
        if let watch = filterWatch {
            return [watch]
        }
        return dataManager.fetchWatches().filter { !$0.serviceRecords.isEmpty }
    }

    private var totalCost: Double {
        watches.flatMap(\.serviceRecords).compactMap(\.cost).reduce(0, +)
    }

    var body: some View {
        Group {
            if watches.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.champagne)
                    Text("No Service Records")
                        .font(.vaultTitle)
                        .foregroundStyle(.white)
                    Text("Log maintenance history for your watches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.vaultBackground)
            } else {
                List {
                    if totalCost > 0 {
                        Section {
                            HStack {
                                Label("Total Service Cost", systemImage: "dollarsign.circle.fill")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(totalCost, format: .currency(code: "USD"))
                                    .foregroundStyle(Color.champagne)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    ForEach(watches) { watch in
                        Section {
                            ForEach(watch.serviceRecords.sorted(by: { $0.serviceDate > $1.serviceDate })) { record in
                                ServiceRecordRow(record: record)
                            }
                            .onDelete { offsets in
                                let sorted = watch.serviceRecords.sorted(by: { $0.serviceDate > $1.serviceDate })
                                for index in offsets {
                                    dataManager.deleteServiceRecord(sorted[index])
                                }
                            }

                            // Service reminder for automatic watches
                            if watch.movementType == .automatic || watch.movementType == .manual {
                                let lastService = watch.serviceRecords.map(\.serviceDate).max()
                                if let last = lastService {
                                    let years = Calendar.current.dateComponents([.year], from: last, to: Date()).year ?? 0
                                    if years >= 5 {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.yellow)
                                            Text("Service recommended — last serviced \(years) years ago")
                                                .font(.caption)
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("\(watch.brand) \(watch.modelName)")
                                Spacer()
                                let watchCost = watch.serviceRecords.compactMap(\.cost).reduce(0, +)
                                if watchCost > 0 {
                                    Text(watchCost, format: .currency(code: "USD"))
                                        .font(.caption)
                                        .foregroundStyle(Color.champagne)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Service Records")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            NavigationStack {
                AddServiceRecordView()
            }
        }
    }
}

private struct ServiceRecordRow: View {
    let record: ServiceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.serviceType)
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                Spacer()
                if let cost = record.cost {
                    Text(cost, format: .currency(code: "USD"))
                        .foregroundStyle(Color.champagne)
                }
            }

            HStack(spacing: 8) {
                Text(record.serviceDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let provider = record.provider, !provider.isEmpty {
                    Text("• \(provider)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}
