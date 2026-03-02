import SwiftUI

@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    // MARK: - Display Preferences

    var currencyCode: String {
        get { UserDefaults.standard.string(forKey: "currencyCode") ?? "USD" }
        set { UserDefaults.standard.set(newValue, forKey: "currencyCode") }
    }

    var collectionSortOrder: CollectionSortOrder {
        get { CollectionSortOrder(rawValue: UserDefaults.standard.string(forKey: "collectionSortOrder") ?? "") ?? .dateAdded }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "collectionSortOrder") }
    }

    var gridColumns: Int {
        get { let v = UserDefaults.standard.integer(forKey: "gridColumns"); return v > 0 ? v : 2 }
        set { UserDefaults.standard.set(newValue, forKey: "gridColumns") }
    }

    var showValuesOnGrid: Bool {
        get { UserDefaults.standard.object(forKey: "showValuesOnGrid") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showValuesOnGrid") }
    }

    // MARK: - Notification Preferences

    var priceAlertNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "priceAlertNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "priceAlertNotifications") }
    }

    var wearReminderEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "wearReminderEnabled") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "wearReminderEnabled") }
    }

    var wearReminderTime: Date {
        get { UserDefaults.standard.object(forKey: "wearReminderTime") as? Date ?? Calendar.current.date(from: DateComponents(hour: 9)) ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "wearReminderTime") }
    }

    var serviceReminderEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "serviceReminderEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "serviceReminderEnabled") }
    }

    // MARK: - Data & Privacy

    var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "iCloudSyncEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    // MARK: - Appearance

    var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appAppearance") }
    }

    var accentColorChoice: AccentColorChoice {
        get { AccentColorChoice(rawValue: UserDefaults.standard.string(forKey: "accentColorChoice") ?? "") ?? .champagne }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "accentColorChoice") }
    }

    // MARK: - Enums

    enum CollectionSortOrder: String, CaseIterable, Identifiable {
        case dateAdded = "dateAdded"
        case brand = "brand"
        case value = "value"
        case lastWorn = "lastWorn"

        var id: String { rawValue }
        var label: String {
            switch self {
            case .dateAdded: "Date Added"
            case .brand: "Brand"
            case .value: "Value"
            case .lastWorn: "Last Worn"
            }
        }
    }

    enum AppAppearance: String, CaseIterable, Identifiable {
        case system, dark, light
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .dark: .dark
            case .light: .light
            }
        }
    }

    enum AccentColorChoice: String, CaseIterable, Identifiable {
        case champagne, gold, silver, blue, green
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .champagne: .champagne
            case .gold: Color(red: 0.85, green: 0.65, blue: 0.13)
            case .silver: Color(red: 0.75, green: 0.75, blue: 0.78)
            case .blue: .blue
            case .green: .green
            }
        }
    }
}
