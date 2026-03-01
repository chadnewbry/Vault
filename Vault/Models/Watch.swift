import Foundation
import SwiftData

enum MovementType: String, Codable, CaseIterable, Identifiable {
    case automatic
    case manual
    case quartz
    case solar
    case springDrive = "spring_drive"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .manual: "Manual"
        case .quartz: "Quartz"
        case .solar: "Solar"
        case .springDrive: "Spring Drive"
        }
    }
}

enum CaseMaterial: String, Codable, CaseIterable, Identifiable {
    case steel, gold, titanium, ceramic, platinum, bronze, other

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

@Model
final class Watch {
    var id: UUID
    var brand: String
    var modelName: String
    var referenceNumber: String?
    var serialNumber: String?
    var movementType: MovementType
    var caseSize: Double?
    var caseMaterial: CaseMaterial
    var dialColor: String?
    var complications: [String]
    var purchaseDate: Date?
    var purchasePrice: Double?
    var currentValue: Double?
    var lastValueUpdate: Date?
    var photoFileNames: [String]
    var notes: String?
    var isInWishlist: Bool
    var priceAlertTarget: Double?
    var wishlistOrder: Int
    var listingURL: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WearLog.watch)
    var wearLogs: [WearLog]

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.watch)
    var serviceRecords: [ServiceRecord]

    @Relationship(deleteRule: .cascade, inverse: \InsuranceDocument.watch)
    var insuranceDocuments: [InsuranceDocument]

    @Relationship(deleteRule: .cascade, inverse: \ValueHistory.watch)
    var valueHistory: [ValueHistory]

    init(
        brand: String,
        modelName: String,
        movementType: MovementType = .automatic,
        caseMaterial: CaseMaterial = .steel,
        isInWishlist: Bool = false
    ) {
        self.id = UUID()
        self.brand = brand
        self.modelName = modelName
        self.movementType = movementType
        self.caseMaterial = caseMaterial
        self.complications = []
        self.photoFileNames = []
        self.isInWishlist = isInWishlist
        self.wishlistOrder = 0
        self.createdAt = Date()
        self.wearLogs = []
        self.serviceRecords = []
        self.insuranceDocuments = []
        self.valueHistory = []
    }

    var appreciation: Double? {
        guard let purchase = purchasePrice, let current = currentValue else { return nil }
        return current - purchase
    }

    var appreciationPercentage: Double? {
        guard let purchase = purchasePrice, purchase > 0, let current = currentValue else { return nil }
        return ((current - purchase) / purchase) * 100
    }

    var wearCount: Int { wearLogs.count }

    var lastWorn: Date? {
        wearLogs.map(\.date).max()
    }
}
