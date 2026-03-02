import SwiftUI

struct InsuranceSummaryView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showingShareSheet = false

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var totalValue: Double {
        watches.compactMap(\.currentValue).reduce(0, +)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Watches")
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(watches.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Insured Value")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(totalValue, format: .currency(code: "USD"))
                        .foregroundStyle(Color.champagne)
                        .fontWeight(.semibold)
                }
            } header: {
                Text("Summary")
            }

            Section("Collection") {
                ForEach(watches) { watch in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(watch.brand) \(watch.modelName)")
                            .foregroundStyle(.white)
                            .fontWeight(.medium)

                        HStack(spacing: 16) {
                            if let serial = watch.serialNumber, !serial.isEmpty {
                                Text("S/N: \(serial)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let value = watch.currentValue {
                                Text(value, format: .currency(code: "USD"))
                                    .font(.caption)
                                    .foregroundStyle(Color.champagne)
                            }
                        }

                        let docCount = watch.insuranceDocuments.count
                        let serviceCount = watch.serviceRecords.count
                        if docCount > 0 || serviceCount > 0 {
                            Text("\(docCount) documents • \(serviceCount) service records")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button {
                    generateAndShare()
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating {
                            ProgressView()
                                .tint(Color.champagne)
                        } else {
                            Label("Generate & Share PDF", systemImage: "square.and.arrow.up")
                                .font(.vaultHeadline)
                                .foregroundStyle(Color.champagne)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isGenerating || watches.isEmpty)
            } footer: {
                Text("Creates a professional PDF with photos, serial numbers, values, and document inventory for your insurance company.")
                    .font(.caption)
            }
        }
        .navigationTitle("Insurance Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func generateAndShare() {
        isGenerating = true
        Task {
            let url = await InsurancePDFService.shared.generateSummary(watches: watches)
            await MainActor.run {
                pdfURL = url
                isGenerating = false
                if url != nil {
                    showingShareSheet = true
                }
            }
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
