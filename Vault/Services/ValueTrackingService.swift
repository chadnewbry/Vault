import Foundation
import SwiftData

/// Service for tracking watch values, manual entry, and calculations.
@Observable
final class ValueTrackingService {
    private let dataManager: DataManager
    var currency: String = "USD"

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    // MARK: - Manual Value Entry

    func recordManualValue(_ value: Double, for watch: Watch, date: Date = Date()) {
        let entry = ValueHistory(watch: watch, date: date, value: value, source: "manual")
        dataManager.addValueHistory(entry)
        dataManager.save()
    }

    func recordMarketValue(_ value: Double, for watch: Watch, date: Date = Date()) {
        let entry = ValueHistory(watch: watch, date: date, value: value, source: "market_data")
        dataManager.addValueHistory(entry)
        dataManager.save()
    }

    // MARK: - Pure Calculations

    static func appreciationPercent(currentValue: Double?, purchasePrice: Double?) -> Double? {
        guard let current = currentValue, let purchase = purchasePrice, purchase > 0 else { return nil }
        return ((current - purchase) / purchase) * 100.0
    }

    static func totalCollectionValue(_ watches: [Watch]) -> Double {
        watches.compactMap(\.currentValue).reduce(0, +)
    }

    static func totalAppreciation(_ watches: [Watch]) -> Double {
        watches.compactMap(\.appreciation).reduce(0, +)
    }

    static func valueOverTime(for watch: Watch) -> [(Date, Double)] {
        watch.valueHistory
            .sorted { $0.date < $1.date }
            .map { ($0.date, $0.value) }
    }

    static func wearCostPerDay(for watch: Watch) -> Double? {
        guard let currentValue = watch.currentValue else { return nil }
        let totalDaysWorn = watch.wearLogs.count
        guard totalDaysWorn > 0 else { return nil }
        return currentValue / Double(totalDaysWorn)
    }

    // MARK: - Market Data Lookup

    func fetchMarketValue(for watch: Watch, provider: MarketDataProvider) async {
        guard let refNumber = watch.referenceNumber, !refNumber.isEmpty else { return }

        // Rate limit: max 1 lookup per watch per day
        if let lastUpdate = watch.valueHistory
            .filter({ $0.source == "market_data" })
            .map(\.date)
            .max(),
           Calendar.current.isDateInToday(lastUpdate) {
            return
        }

        do {
            if let price = try await provider.fetchPrice(referenceNumber: refNumber) {
                await MainActor.run {
                    recordMarketValue(price, for: watch)
                }
            }
        } catch {
            print("Market data fetch failed for \(refNumber): \(error.localizedDescription)")
        }
    }
}
