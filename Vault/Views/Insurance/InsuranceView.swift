import SwiftUI
import SwiftData

struct InsuranceView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var showingSummary = false

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var totalDocuments: Int {
        watches.reduce(0) { $0 + $1.insuranceDocuments.count }
    }

    private var totalServiceRecords: Int {
        watches.reduce(0) { $0 + $1.serviceRecords.count }
    }

    private var totalServiceCost: Double {
        watches.flatMap(\.serviceRecords).compactMap(\.cost).reduce(0, +)
    }

    var body: some View {
        List {
            // Overview Section
            Section {
                HStack {
                    Label("Total Collection Value", systemImage: "banknote.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(dataManager.totalCollectionValue, format: .currency(code: "USD"))
                        .foregroundStyle(Color.champagne)
                        .fontWeight(.semibold)
                }

                HStack {
                    Label("Watches in Collection", systemImage: "watch.analog")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(watches.count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Overview")
            }

            // Documents Section
            Section {
                NavigationLink {
                    DocumentListView()
                } label: {
                    HStack {
                        Label("All Documents", systemImage: "doc.text.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(totalDocuments)")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(watches.filter { !$0.insuranceDocuments.isEmpty }) { watch in
                    NavigationLink {
                        DocumentListView(filterWatch: watch)
                    } label: {
                        HStack {
                            Text("\(watch.brand) \(watch.modelName)")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(watch.insuranceDocuments.count) docs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Documents")
            }

            // Service Records Section
            Section {
                NavigationLink {
                    ServiceRecordListView()
                } label: {
                    HStack {
                        Label("All Service Records", systemImage: "wrench.and.screwdriver.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(totalServiceRecords)")
                            .foregroundStyle(.secondary)
                    }
                }

                if totalServiceCost > 0 {
                    HStack {
                        Label("Total Service Cost", systemImage: "dollarsign.circle.fill")
                            .foregroundStyle(.white)
                        Spacer()
                        Text(totalServiceCost, format: .currency(code: "USD"))
                            .foregroundStyle(Color.champagne)
                    }
                }
            } header: {
                Text("Service Records")
            }

            // Generate Summary Section
            Section {
                Button {
                    showingSummary = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Generate Insurance Summary", systemImage: "doc.richtext")
                            .font(.vaultHeadline)
                            .foregroundStyle(Color.champagne)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                Text("Create a professional PDF summary of your collection for your insurance provider.")
                    .font(.caption)
            }
        }
        .navigationTitle("Insurance")
        .sheet(isPresented: $showingSummary) {
            NavigationStack {
                InsuranceSummaryView()
            }
        }
    }
}
