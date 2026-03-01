import SwiftUI
import LocalAuthentication
import StoreKit

// MARK: - Settings Manager

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var defaultCurrency: String {
        get { UserDefaults.standard.string(forKey: "defaultCurrency") ?? "USD" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultCurrency") }
    }

    var preferredBrands: [String] {
        get { UserDefaults.standard.stringArray(forKey: "preferredBrands") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "preferredBrands") }
    }

    var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "system") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appearanceMode") }
    }

    var appLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appLockEnabled") }
    }

    var selectedAppIcon: String {
        get { UserDefaults.standard.string(forKey: "selectedAppIcon") ?? "default" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAppIcon") }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var settings = SettingsManager.shared
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingBrandEditor = false
    @State private var newBrand = ""
    @State private var showingBiometricError = false
    @State private var biometricErrorMessage = ""

    private let currencies = ["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "HKD", "SGD", "CNY"]

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var biometricTypeName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometrics"
        }
    }

    var body: some View {
        List {
            profileSection
            dataSection
            appearanceSection
            privacySection
            aboutSection
        }
        .navigationTitle("Settings")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Authentication Error", isPresented: $showingBiometricError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricErrorMessage)
        }
        .sheet(isPresented: $showingBrandEditor) {
            brandEditorSheet
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            Picker("Default Currency", selection: Binding(
                get: { settings.defaultCurrency },
                set: { settings.defaultCurrency = $0 }
            )) {
                ForEach(currencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }

            Button {
                showingBrandEditor = true
            } label: {
                HStack {
                    Text("Preferred Brands")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(settings.preferredBrands.isEmpty ? "None" : "\(settings.preferredBrands.count) brands")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Profile")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: Binding(
                get: { settings.iCloudSyncEnabled },
                set: { settings.iCloudSyncEnabled = $0 }
            ))

            Button {
                showingExportOptions = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .confirmationDialog("Export Format", isPresented: $showingExportOptions) {
                Button("Export as CSV") { exportData(format: .csv) }
                Button("Export as JSON") { exportData(format: .json) }
                Button("Cancel", role: .cancel) {}
            }

            Button {
                showingImportPicker = true
            } label: {
                Label("Import from Other Apps", systemImage: "square.and.arrow.down")
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.json, .commaSeparatedText]) { result in
                handleImport(result)
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: Binding(
                get: { settings.appearanceMode },
                set: { settings.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            NavigationLink {
                AppIconPickerView()
            } label: {
                HStack {
                    Text("App Icon")
                    Spacer()
                    Text(settings.selectedAppIcon == "default" ? "Default" : settings.selectedAppIcon.capitalized)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle("\(biometricTypeName) Lock", isOn: Binding(
                get: { settings.appLockEnabled },
                set: { newValue in
                    if newValue {
                        authenticateForLock()
                    } else {
                        settings.appLockEnabled = false
                    }
                }
            ))
        } header: {
            Text("Privacy")
        } footer: {
            Text("Require \(biometricTypeName) to open Vault")
        }
    }

    // MARK: - About & Legal Section

    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://chadnewbry.github.io/Vault/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://chadnewbry.github.io/Vault/terms")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }

            Button {
                sendSupportEmail()
            } label: {
                Label("Customer Support", systemImage: "envelope.fill")
            }

            HStack {
                Text("App Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Button {
                requestAppReview()
            } label: {
                Label("Rate Vault", systemImage: "star.fill")
            }

            ShareLink(item: URL(string: "https://apps.apple.com/app/vault-watch-collection/id0000000000")!) {
                Label("Share Vault", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("About & Legal")
        }
    }

    // MARK: - Brand Editor Sheet

    private var brandEditorSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add brand", text: $newBrand)
                        Button {
                            let trimmed = newBrand.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty, !settings.preferredBrands.contains(trimmed) else { return }
                            settings.preferredBrands.append(trimmed)
                            newBrand = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.champagne)
                        }
                        .disabled(newBrand.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    ForEach(settings.preferredBrands, id: \.self) { brand in
                        Text(brand)
                    }
                    .onDelete { offsets in
                        settings.preferredBrands.remove(atOffsets: offsets)
                    }
                }
            }
            .navigationTitle("Preferred Brands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingBrandEditor = false }
                }
            }
        }
    }

    // MARK: - Actions

    private func authenticateForLock() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricErrorMessage = error?.localizedDescription ?? "\(biometricTypeName) is not available on this device."
            showingBiometricError = true
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable \(biometricTypeName) lock for Vault") { success, error in
            DispatchQueue.main.async {
                if success {
                    settings.appLockEnabled = true
                } else if let error {
                    biometricErrorMessage = error.localizedDescription
                    showingBiometricError = true
                }
            }
        }
    }

    private func sendSupportEmail() {
        let subject = "Vault Support"
        let email = "chad.newbry@gmail.com"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }

    private func exportData(format: ExportFormat) {
        let watches = DataManager.shared.fetchWatches(includeWishlist: true)

        let content: String
        let fileExtension: String

        switch format {
        case .csv:
            content = generateCSV(from: watches)
            fileExtension = "csv"
        case .json:
            content = generateJSON(from: watches)
            fileExtension = "json"
        }

        let fileName = "vault_export_\(Date().formatted(.iso8601.year().month().day())).\(fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            // Export failed silently
        }
    }

    private func generateCSV(from watches: [Watch]) -> String {
        var csv = "Brand,Model,Reference,Serial,Movement,Case Size,Case Material,Dial Color,Purchase Date,Purchase Price,Current Value,Notes,Wishlist\n"
        for w in watches {
            var row: [String] = []
            row.append(w.brand)
            row.append(w.modelName)
            row.append(w.referenceNumber ?? "")
            row.append(w.serialNumber ?? "")
            row.append(w.movementType.displayName)
            row.append(w.caseSize.map { String($0) } ?? "")
            row.append(w.caseMaterial.displayName)
            row.append(w.dialColor ?? "")
            row.append(w.purchaseDate?.formatted(.iso8601) ?? "")
            row.append(w.purchasePrice.map { String($0) } ?? "")
            row.append(w.currentValue.map { String($0) } ?? "")
            row.append(w.notes ?? "")
            row.append(w.isInWishlist ? "Yes" : "No")
            let escaped = row.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
            csv += escaped.joined(separator: ",") + "\n"
        }
        return csv
    }

    private func generateJSON(from watches: [Watch]) -> String {
        let items: [[String: Any]] = watches.map { w in
            var dict: [String: Any] = [
                "brand": w.brand,
                "model": w.modelName,
                "movement": w.movementType.rawValue,
                "caseMaterial": w.caseMaterial.rawValue,
                "isWishlist": w.isInWishlist
            ]
            if let ref = w.referenceNumber { dict["reference"] = ref }
            if let serial = w.serialNumber { dict["serial"] = serial }
            if let size = w.caseSize { dict["caseSize"] = size }
            if let dial = w.dialColor { dict["dialColor"] = dial }
            if let date = w.purchaseDate { dict["purchaseDate"] = date.formatted(.iso8601) }
            if let price = w.purchasePrice { dict["purchasePrice"] = price }
            if let value = w.currentValue { dict["currentValue"] = value }
            if let notes = w.notes { dict["notes"] = notes }
            return dict
        }

        guard let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private func handleImport(_ result: Result<URL, Error>) {
        // Placeholder — import parsing would go here based on file type
    }
}

enum ExportFormat {
    case csv, json
}

// MARK: - App Icon Picker

struct AppIconPickerView: View {
    @State private var settings = SettingsManager.shared

    private let icons = [
        ("default", "Default"),
        ("dark", "Dark"),
        ("gold", "Gold"),
        ("midnight", "Midnight")
    ]

    var body: some View {
        List {
            ForEach(icons, id: \.0) { icon in
                Button {
                    setAppIcon(icon.0)
                } label: {
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconColor(for: icon.0))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )

                        Text(icon.1)
                            .foregroundStyle(.primary)
                            .padding(.leading, 12)

                        Spacer()

                        if settings.selectedAppIcon == icon.0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.champagne)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func iconColor(for name: String) -> Color {
        switch name {
        case "dark": return .black
        case "gold": return Color.champagne
        case "midnight": return Color(red: 0.1, green: 0.1, blue: 0.2)
        default: return Color.vaultSurface
        }
    }

    private func setAppIcon(_ name: String) {
        settings.selectedAppIcon = name
        let iconName: String? = name == "default" ? nil : "AppIcon-\(name.capitalized)"
        UIApplication.shared.setAlternateIconName(iconName)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}
