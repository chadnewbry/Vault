import Foundation
import SwiftData

enum DocType: String, Codable, CaseIterable, Identifiable {
    case receipt, appraisal, warranty, serviceRecord, photo, certificateOfAuthenticity, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .receipt: "Receipt"
        case .appraisal: "Appraisal"
        case .warranty: "Warranty Card"
        case .serviceRecord: "Service Record"
        case .photo: "Photo"
        case .certificateOfAuthenticity: "Certificate of Authenticity"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .receipt: "receipt"
        case .appraisal: "doc.text.magnifyingglass"
        case .warranty: "checkmark.seal.fill"
        case .serviceRecord: "wrench.and.screwdriver.fill"
        case .photo: "photo.fill"
        case .certificateOfAuthenticity: "rosette"
        case .other: "doc.fill"
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
    var notes: String?

    init(watch: Watch, documentType: DocType, imageFileName: String, title: String, date: Date? = nil, notes: String? = nil) {
        self.id = UUID()
        self.watch = watch
        self.documentType = documentType
        self.imageFileName = imageFileName
        self.title = title
        self.date = date
        self.notes = notes
    }
}
