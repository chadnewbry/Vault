import Foundation

enum ServiceType: String, CaseIterable, Identifiable {
    case battery = "Battery Replacement"
    case fullService = "Full Service"
    case repair = "Repair"
    case polish = "Polish"
    case crystalReplacement = "Crystal Replacement"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .battery: "battery.100.bolt"
        case .fullService: "gearshape.2.fill"
        case .repair: "wrench.fill"
        case .polish: "sparkles"
        case .crystalReplacement: "circle.dashed"
        case .other: "ellipsis.circle.fill"
        }
    }
}
