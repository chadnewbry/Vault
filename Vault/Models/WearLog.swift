import Foundation
import SwiftData

@Model
final class WearLog {
    var id: UUID
    var watch: Watch?
    var date: Date
    var occasion: String?
    var notes: String?

    init(watch: Watch, date: Date = Date(), occasion: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.watch = watch
        self.date = date
        self.occasion = occasion
        self.notes = notes
    }
}
