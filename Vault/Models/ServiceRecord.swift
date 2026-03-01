import Foundation
import SwiftData

@Model
final class ServiceRecord {
    var id: UUID
    var watch: Watch?
    var serviceDate: Date
    var serviceType: String
    var provider: String?
    var cost: Double?
    var notes: String?

    init(watch: Watch, serviceDate: Date, serviceType: String) {
        self.id = UUID()
        self.watch = watch
        self.serviceDate = serviceDate
        self.serviceType = serviceType
    }
}
