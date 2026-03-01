import Foundation
import SwiftData
import SwiftUI

@Observable
final class DataManager {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    static let shared: DataManager = {
        do {
            return try DataManager()
        } catch {
            fatalError("Failed to initialize DataManager: \(error)")
        }
    }()

    init() throws {
        let schema = Schema([
            Watch.self,
            WearLog.self,
            ServiceRecord.self,
            InsuranceDocument.self,
            ValueHistory.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    // MARK: - Watch CRUD

    func addWatch(_ watch: Watch) {
        modelContext.insert(watch)
    }

    func deleteWatch(_ watch: Watch) {
        for fileName in watch.photoFileNames {
            Task { await PhotoStorageService.shared.deletePhoto(named: fileName) }
        }
        for doc in watch.insuranceDocuments {
            Task { await PhotoStorageService.shared.deletePhoto(named: doc.imageFileName) }
        }
        modelContext.delete(watch)
    }

    func fetchWatches(includeWishlist: Bool = false) -> [Watch] {
        let predicate: Predicate<Watch>
        if includeWishlist {
            predicate = #Predicate<Watch> { _ in true }
        } else {
            predicate = #Predicate<Watch> { !$0.isInWishlist }
        }
        let descriptor = FetchDescriptor<Watch>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchWishlist() -> [Watch] {
        let descriptor = FetchDescriptor<Watch>(
            predicate: #Predicate { $0.isInWishlist },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - WearLog CRUD

    func addWearLog(_ log: WearLog) {
        modelContext.insert(log)
    }

    func deleteWearLog(_ log: WearLog) {
        modelContext.delete(log)
    }

    func fetchWearLogs(for watch: Watch) -> [WearLog] {
        let watchId = watch.id
        let descriptor = FetchDescriptor<WearLog>(
            predicate: #Predicate { $0.watch?.id == watchId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - ServiceRecord CRUD

    func addServiceRecord(_ record: ServiceRecord) {
        modelContext.insert(record)
    }

    func deleteServiceRecord(_ record: ServiceRecord) {
        modelContext.delete(record)
    }

    // MARK: - InsuranceDocument CRUD

    func addInsuranceDocument(_ doc: InsuranceDocument) {
        modelContext.insert(doc)
    }

    func deleteInsuranceDocument(_ doc: InsuranceDocument) {
        Task { await PhotoStorageService.shared.deletePhoto(named: doc.imageFileName) }
        modelContext.delete(doc)
    }

    // MARK: - ValueHistory CRUD

    func addValueHistory(_ entry: ValueHistory) {
        modelContext.insert(entry)
        entry.watch?.currentValue = entry.value
        entry.watch?.lastValueUpdate = entry.date
    }

    func deleteValueHistory(_ entry: ValueHistory) {
        modelContext.delete(entry)
    }

    // MARK: - Computed Aggregates

    var totalCollectionValue: Double {
        fetchWatches().compactMap(\.currentValue).reduce(0, +)
    }

    var totalAppreciation: Double {
        fetchWatches().compactMap(\.appreciation).reduce(0, +)
    }

    func wearFrequency(for watch: Watch, days: Int = 30) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let count = watch.wearLogs.filter { $0.date >= cutoff }.count
        return Double(count) / Double(days)
    }

    // MARK: - Save

    func save() {
        try? modelContext.save()
    }
}
