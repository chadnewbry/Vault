import Foundation
import StoreKit

@Observable
final class StoreManager {
    static let productID = "com.chadnewbry.vault.premium"
    static let freeWatchLimit = 5

    private(set) var isPremium = false
    private(set) var product: Product?
    private(set) var purchaseState: PurchaseState = .idle
    private var transactionListener: Task<Void, Never>?

    enum PurchaseState: Equatable {
        case idle, purchasing, purchased, failed(String), restored
    }

    init() {
        transactionListener = listenForTransactions()
        Task { await checkEntitlement() }
        Task { await loadProduct() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public

    func canAddWatch(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freeWatchLimit
    }

    func freeRemaining(currentCount: Int) -> Int {
        max(0, Self.freeWatchLimit - currentCount)
    }

    func purchase() async {
        guard let product else {
            purchaseState = .failed("Product not available")
            return
        }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    isPremium = true
                    purchaseState = .purchased
                } else {
                    purchaseState = .failed("Verification failed")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await checkEntitlement()
        if isPremium {
            purchaseState = .restored
        }
    }

    // MARK: - Private

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    private func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                isPremium = true
                return
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    if transaction.productID == StoreManager.productID {
                        await MainActor.run {
                            self?.isPremium = transaction.revocationDate == nil
                        }
                    }
                }
            }
        }
    }
}
