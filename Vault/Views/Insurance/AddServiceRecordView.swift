import SwiftUI

struct AddServiceRecordView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss

    var preselectedWatch: Watch? = nil
    @State private var selectedWatch: Watch?
    @State private var serviceDate = Date()
    @State private var serviceType: ServiceType = .fullService
    @State private var provider = ""
    @State private var costString = ""
    @State private var notes = ""

    private var watches: [Watch] {
        dataManager.fetchWatches()
    }

    private var canSave: Bool {
        selectedWatch != nil
    }

    var body: some View {
        Form {
            Section("Watch") {
                Picker("Watch", selection: $selectedWatch) {
                    Text("Select a watch").tag(nil as Watch?)
                    ForEach(watches) { watch in
                        Text("\(watch.brand) \(watch.modelName)").tag(watch as Watch?)
                    }
                }
            }

            Section("Service Details") {
                Picker("Type", selection: $serviceType) {
                    ForEach(ServiceType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                DatePicker("Date", selection: $serviceDate, displayedComponents: .date)

                TextField("Provider (optional)", text: $provider)

                TextField("Cost (optional)", text: $costString)
                    .keyboardType(.decimalPad)

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Service reminder info
            if let watch = selectedWatch,
               (watch.movementType == .automatic || watch.movementType == .manual) {
                Section {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.champagne)
                        Text("Automatic and manual watches should be serviced every 5–7 years to maintain accuracy and longevity.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Add Service Record")
        .onAppear { if selectedWatch == nil { selectedWatch = preselectedWatch } }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Color.champagne : .gray)
            }
        }
    }

    private func save() {
        guard let watch = selectedWatch else { return }

        let record = ServiceRecord(
            watch: watch,
            serviceDate: serviceDate,
            serviceType: serviceType.rawValue
        )
        record.provider = provider.isEmpty ? nil : provider
        record.cost = Double(costString)
        record.notes = notes.isEmpty ? nil : notes

        dataManager.addServiceRecord(record)
        dataManager.save()
        dismiss()
    }
}
