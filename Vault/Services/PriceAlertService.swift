import Foundation
import UserNotifications

/// Checks wishlist watches against their target prices and sends local notifications.
final class PriceAlertService {
    private let dataManager: DataManager

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    /// Request notification permissions.
    func requestNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Check all wishlist watches with a target price against current market/manual values.
    /// Sends a local notification for each watch that has dropped to or below the target.
    func checkPriceAlerts(provider: MarketDataProvider = StubMarketDataProvider()) async {
        let wishlist = dataManager.fetchWishlist()
        let watchesWithAlerts = wishlist.filter { $0.priceAlertTarget != nil }

        for watch in watchesWithAlerts {
            guard let target = watch.priceAlertTarget else { continue }

            // Try to get a fresh market value if reference number exists
            if let ref = watch.referenceNumber, !ref.isEmpty {
                do {
                    if let price = try await provider.fetchPrice(referenceNumber: ref) {
                        await MainActor.run {
                            let entry = ValueHistory(watch: watch, date: Date(), value: price, source: "market_data")
                            dataManager.addValueHistory(entry)
                            dataManager.save()
                        }
                    }
                } catch {
                    // Continue with existing value
                }
            }

            if let currentValue = watch.currentValue, currentValue <= target {
                await sendPriceAlert(for: watch, currentPrice: currentValue, targetPrice: target)
            }
        }
    }

    private func sendPriceAlert(for watch: Watch, currentPrice: Double, targetPrice: Double) async {
        let content = UNMutableNotificationContent()
        content.title = "Price Alert: \(watch.brand) \(watch.modelName)"
        content.body = String(format: "Now $%.0f — at or below your target of $%.0f", currentPrice, targetPrice)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "price-alert-\(watch.id.uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
