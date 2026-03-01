import SwiftUI
import SwiftData

@main
struct VaultApp: App {
    let dataManager: DataManager

    init() {
        do {
            dataManager = try DataManager()
        } catch {
            fatalError("Failed to initialize data: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(dataManager)
        }
        .modelContainer(dataManager.modelContainer)
    }
}
