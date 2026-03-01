import SwiftUI
import SwiftData

struct DocumentListView: View {
    @Environment(DataManager.self) private var dataManager
    var filterWatch: Watch? = nil

    @State private var showingAddDocument = false

    private var watches: [Watch] {
        if let watch = filterWatch {
            return [watch]
        }
        return dataManager.fetchWatches().filter { !$0.insuranceDocuments.isEmpty }
    }

    var body: some View {
        Group {
            if watches.isEmpty || watches.allSatisfy({ $0.insuranceDocuments.isEmpty }) {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.champagne)
                    Text("No Documents")
                        .font(.vaultTitle)
                        .foregroundStyle(.white)
                    Text("Add receipts, appraisals, and warranty cards for your watches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.vaultBackground)
            } else {
                List {
                    ForEach(watches) { watch in
                        Section {
                            ForEach(watch.insuranceDocuments.sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })) { doc in
                                NavigationLink {
                                    DocumentDetailView(document: doc)
                                } label: {
                                    DocumentRow(document: doc)
                                }
                            }
                            .onDelete { offsets in
                                let sorted = watch.insuranceDocuments.sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
                                for index in offsets {
                                    dataManager.deleteInsuranceDocument(sorted[index])
                                }
                            }
                        } header: {
                            Text("\(watch.brand) \(watch.modelName)")
                        }
                    }
                }
            }
        }
        .navigationTitle(filterWatch != nil ? "\(filterWatch!.brand) Docs" : "Documents")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddDocument = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.champagne)
                }
            }
        }
        .sheet(isPresented: $showingAddDocument) {
            NavigationStack {
                AddDocumentView(preselectedWatch: filterWatch)
            }
        }
    }
}

private struct DocumentRow: View {
    let document: InsuranceDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.documentType.icon)
                .font(.title3)
                .foregroundStyle(Color.champagne)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(document.documentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let date = document.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
