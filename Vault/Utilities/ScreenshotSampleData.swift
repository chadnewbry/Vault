import Foundation
import SwiftData

#if DEBUG
enum ScreenshotSampleData {
    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }

    static func populate(context: ModelContext) {
        // Clear existing data
        try? context.delete(model: WearLog.self)
        try? context.delete(model: ServiceRecord.self)
        try? context.delete(model: InsuranceDocument.self)
        try? context.delete(model: ValueHistory.self)
        try? context.delete(model: Watch.self)

        let calendar = Calendar.current
        let now = Date()

        // MARK: - Collection Watches

        let submariner = Watch(brand: "Rolex", modelName: "Submariner Date", movementType: .automatic, caseMaterial: .steel)
        submariner.referenceNumber = "126610LN"
        submariner.serialNumber = "3X7R9K2P"
        submariner.caseSize = 41
        submariner.dialColor = "Black"
        submariner.complications = ["Date"]
        submariner.purchaseDate = calendar.date(byAdding: .month, value: -18, to: now)
        submariner.purchasePrice = 9150
        submariner.currentValue = 12800
        submariner.lastValueUpdate = calendar.date(byAdding: .day, value: -2, to: now)
        submariner.notes = "AD purchase, full kit with box and papers"
        context.insert(submariner)

        let speedmaster = Watch(brand: "Omega", modelName: "Speedmaster Professional", movementType: .manual, caseMaterial: .steel)
        speedmaster.referenceNumber = "310.30.42.50.01.002"
        speedmaster.caseSize = 42
        speedmaster.dialColor = "Black"
        speedmaster.complications = ["Chronograph", "Tachymeter"]
        speedmaster.purchaseDate = calendar.date(byAdding: .month, value: -24, to: now)
        speedmaster.purchasePrice = 6300
        speedmaster.currentValue = 5950
        speedmaster.lastValueUpdate = calendar.date(byAdding: .day, value: -5, to: now)
        speedmaster.notes = "Moonwatch, hesalite crystal"
        context.insert(speedmaster)

        let royalOak = Watch(brand: "Audemars Piguet", modelName: "Royal Oak", movementType: .automatic, caseMaterial: .steel)
        royalOak.referenceNumber = "15500ST.OO.1220ST.01"
        royalOak.caseSize = 41
        royalOak.dialColor = "Blue"
        royalOak.complications = ["Date"]
        royalOak.purchaseDate = calendar.date(byAdding: .month, value: -8, to: now)
        royalOak.purchasePrice = 35000
        royalOak.currentValue = 42500
        royalOak.lastValueUpdate = calendar.date(byAdding: .day, value: -1, to: now)
        context.insert(royalOak)

        let tank = Watch(brand: "Cartier", modelName: "Tank Française", movementType: .quartz, caseMaterial: .steel)
        tank.referenceNumber = "WSTA0065"
        tank.caseSize = 32
        tank.dialColor = "Silver"
        tank.complications = []
        tank.purchaseDate = calendar.date(byAdding: .month, value: -6, to: now)
        tank.purchasePrice = 4050
        tank.currentValue = 4200
        tank.lastValueUpdate = calendar.date(byAdding: .day, value: -3, to: now)
        context.insert(tank)

        let snowflake = Watch(brand: "Grand Seiko", modelName: "Snowflake", movementType: .springDrive, caseMaterial: .titanium)
        snowflake.referenceNumber = "SBGA211"
        snowflake.caseSize = 41
        snowflake.dialColor = "White"
        snowflake.complications = ["Date", "Power Reserve"]
        snowflake.purchaseDate = calendar.date(byAdding: .month, value: -12, to: now)
        snowflake.purchasePrice = 5800
        snowflake.currentValue = 6100
        snowflake.lastValueUpdate = calendar.date(byAdding: .day, value: -4, to: now)
        context.insert(snowflake)

        // MARK: - Wishlist Watches

        let nautilus = Watch(brand: "Patek Philippe", modelName: "Nautilus", movementType: .automatic, caseMaterial: .steel, isInWishlist: true)
        nautilus.referenceNumber = "5711/1A-010"
        nautilus.currentValue = 128000
        nautilus.listingURL = "https://www.chrono24.com"
        nautilus.priceAlertTarget = 120000
        context.insert(nautilus)

        let daytona = Watch(brand: "Rolex", modelName: "Cosmograph Daytona", movementType: .automatic, caseMaterial: .steel, isInWishlist: true)
        daytona.referenceNumber = "126500LN"
        daytona.currentValue = 28500
        daytona.listingURL = "https://www.chrono24.com"
        daytona.priceAlertTarget = 26000
        context.insert(daytona)

        let reverso = Watch(brand: "Jaeger-LeCoultre", modelName: "Reverso Classic", movementType: .manual, caseMaterial: .steel, isInWishlist: true)
        reverso.referenceNumber = "Q3858520"
        reverso.currentValue = 7200
        context.insert(reverso)

        // MARK: - Wear Logs (last 30 days, realistic rotation)

        let collectionWatches = [submariner, speedmaster, royalOak, tank, snowflake]
        let occasions: [String?] = ["Office", "Dinner", "Weekend", "Travel", "Special Event", nil]
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let watch = collectionWatches[dayOffset % collectionWatches.count]
            let occasion = occasions[dayOffset % occasions.count]
            let log = WearLog(watch: watch, date: date, occasion: occasion)
            context.insert(log)
        }

        // MARK: - Service Records

        let subService = ServiceRecord(watch: submariner, serviceDate: calendar.date(byAdding: .month, value: -3, to: now)!, serviceType: ServiceType.fullService.rawValue)
        subService.provider = "Rolex Service Center"
        subService.cost = 850
        context.insert(subService)

        let speedService = ServiceRecord(watch: speedmaster, serviceDate: calendar.date(byAdding: .month, value: -6, to: now)!, serviceType: ServiceType.crystalReplacement.rawValue)
        speedService.provider = "Omega Boutique"
        speedService.cost = 120
        context.insert(speedService)

        // MARK: - Value History (monthly entries for trending)

        let valueData: [(Watch, [(Int, Double)])] = [
            (submariner, [(-18, 9150), (-12, 10200), (-6, 11500), (-3, 12100), (0, 12800)]),
            (royalOak, [(-8, 35000), (-6, 37000), (-3, 40000), (0, 42500)]),
            (speedmaster, [(-24, 6300), (-18, 6100), (-12, 5900), (-6, 5800), (0, 5950)]),
            (snowflake, [(-12, 5800), (-6, 5900), (-3, 6000), (0, 6100)]),
            (tank, [(-6, 4050), (-3, 4100), (0, 4200)])
        ]

        for (watch, entries) in valueData {
            for (monthOffset, value) in entries {
                if let date = calendar.date(byAdding: .month, value: monthOffset, to: now) {
                    let history = ValueHistory(watch: watch, date: date, value: value, source: "manual")
                    context.insert(history)
                }
            }
        }

        try? context.save()
    }
}
#endif
