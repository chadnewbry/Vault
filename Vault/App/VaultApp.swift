import SwiftUI
import SwiftData

@main
struct VaultApp: App {
    let dataManager: DataManager
    private let priceAlertService: PriceAlertService
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            dataManager = try DataManager()
        } catch {
            fatalError("Failed to initialize data: \(error)")
        }
        priceAlertService = PriceAlertService(dataManager: dataManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(dataManager)
                .task {
                    await priceAlertService.requestNotificationPermission()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await priceAlertService.checkPriceAlerts()
                        }
                    }
                }
        }
        .modelContainer(dataManager.modelContainer)
    }
}
