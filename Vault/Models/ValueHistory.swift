import Foundation
import SwiftData

@Model
final class ValueHistory {
    var id: UUID
    var watch: Watch?
    var date: Date
    var value: Double
    var source: String

    init(watch: Watch, date: Date = Date(), value: Double, source: String = "manual") {
        self.id = UUID()
        self.watch = watch
        self.date = date
        self.value = value
        self.source = source
    }
}
