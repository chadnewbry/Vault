import Foundation
import SwiftData

enum DocType: String, Codable, CaseIterable, Identifiable {
    case receipt, appraisal, warranty, serviceRecord, photo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receipt: "Receipt"
        case .appraisal: "Appraisal"
        case .warranty: "Warranty"
        case .serviceRecord: "Service Record"
        case .photo: "Photo"
        }
    }
}

@Model
final class InsuranceDocument {
    var id: UUID
    var watch: Watch?
    var documentType: DocType
    var imageFileName: String
    var title: String
    var date: Date?

    init(watch: Watch, documentType: DocType, imageFileName: String, title: String, date: Date? = nil) {
        self.id = UUID()
        self.watch = watch
        self.documentType = documentType
        self.imageFileName = imageFileName
        self.title = title
        self.date = date
    }
}
