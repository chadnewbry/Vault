import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var preferences = UserPreferences.shared
    @State private var showExportSheet = false
    @State private var showResetAlert = false
    @State private var exportFileURL: URL?
    private let baseURL = "https://chadnewbry.github.io/Vault/"

    var body: some View {
        List {
            // MARK: - Appearance

            Section {
                Picker("Appearance", selection: $preferences.appAppearance) {
                    ForEach(UserPreferences.AppAppearance.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }

                Picker("Accent Color", selection: $preferences.accentColorChoice) {
                    ForEach(UserPreferences.AccentColorChoice.allCases) { option in
                        HStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 14, height: 14)
                            Text(option.label)
                        }
                        .tag(option)
                    }
                }
            } header: {
                Text("Appearance")
            }

            // MARK: - Collection Display

            Section {
                Picker("Default Sort", selection: $preferences.collectionSortOrder) {
                    ForEach(UserPreferences.CollectionSortOrder.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }

                Stepper("Grid Columns: \(preferences.gridColumns)", value: $preferences.gridColumns, in: 1...4)

                Toggle("Show Values on Grid", isOn: $preferences.showValuesOnGrid)
            } header: {
                Text("Collection Display")
            }

            // MARK: - Currency

            Section {
                Picker("Currency", selection: $preferences.currencyCode) {
                    ForEach(Self.currencies, id: \.code) { currency in
                        Text("\(currency.symbol) \(currency.code)").tag(currency.code)
                    }
                }
            } header: {
                Text("Currency")
            }

            // MARK: - Notifications

            Section {
                Toggle("Price Alert Notifications", isOn: $preferences.priceAlertNotifications)

                Toggle("Service Reminders", isOn: $preferences.serviceReminderEnabled)

                Toggle("Daily Wear Reminder", isOn: $preferences.wearReminderEnabled)

                if preferences.wearReminderEnabled {
                    DatePicker("Reminder Time", selection: $preferences.wearReminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Notifications")
            }

            // MARK: - Data & Privacy

            Section {
                Toggle("iCloud Sync", isOn: $preferences.iCloudSyncEnabled)

                Button {
                    exportData()
                } label: {
                    Label("Export Collection Data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("Reset All Preferences", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Data & Privacy")
            }

            // MARK: - About

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "\(baseURL)support.html")!) {
                    Label("Support", systemImage: "questionmark.circle.fill")
                }

                Link(destination: URL(string: "\(baseURL)privacy-policy.html")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }

                Link(destination: URL(string: "\(baseURL)terms-of-service.html")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            } header: {
                Text("About")
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Reset Preferences", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetPreferences()
            }
        } message: {
            Text("This will reset all settings to their default values. Your collection data will not be affected.")
        }
    }

    // MARK: - Currencies

    private static let currencies: [(code: String, symbol: String)] = [
        ("USD", "$"), ("EUR", "€"), ("GBP", "£"), ("JPY", "¥"),
        ("CHF", "CHF"), ("AUD", "A$"), ("CAD", "C$"), ("HKD", "HK$")
    ]

    // MARK: - Export

    private func exportData() {
        let watches = dataManager.fetchWatches(includeWishlist: true)
        var csvRows = ["Brand,Model,Reference,Purchase Price,Current Value,Purchase Date,Is Wishlist"]
        for w in watches {
            let brand = w.brand.replacingOccurrences(of: ",", with: ";")
            let model = (w.modelName).replacingOccurrences(of: ",", with: ";")
            let ref = (w.referenceNumber ?? "").replacingOccurrences(of: ",", with: ";")
            let price = w.purchasePrice.map { String($0) } ?? ""
            let value = w.currentValue.map { String($0) } ?? ""
            let date = w.purchaseDate.map { ISO8601DateFormatter().string(from: $0) } ?? ""
            csvRows.append("\(brand),\(model),\(ref),\(price),\(value),\(date),\(w.isInWishlist)")
        }
        let csv = csvRows.joined(separator: "\n")
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("vault_export.csv")
        try? csv.write(to: tmpURL, atomically: true, encoding: .utf8)
        exportFileURL = tmpURL
        showExportSheet = true
    }

    // MARK: - Reset

    private func resetPreferences() {
        let keys = ["currencyCode", "collectionSortOrder", "gridColumns", "showValuesOnGrid",
                     "priceAlertNotifications", "wearReminderEnabled", "wearReminderTime",
                     "serviceReminderEnabled", "iCloudSyncEnabled", "appAppearance", "accentColorChoice"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        preferences = UserPreferences.shared
    }
}

// MARK: - ShareSheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(try! DataManager())
    }
    .preferredColorScheme(.dark)
}
