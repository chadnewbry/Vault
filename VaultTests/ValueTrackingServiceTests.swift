import Testing
import Foundation
@testable import Vault

struct ValueTrackingCalculationTests {

    // MARK: - appreciationPercent

    @Test func appreciationPercent_positive() {
        let result = ValueTrackingService.appreciationPercent(currentValue: 12000, purchasePrice: 10000)
        #expect(result == 20.0)
    }

    @Test func appreciationPercent_negative() {
        let result = ValueTrackingService.appreciationPercent(currentValue: 8000, purchasePrice: 10000)
        #expect(result == -20.0)
    }

    @Test func appreciationPercent_nilCurrentValue() {
        let result = ValueTrackingService.appreciationPercent(currentValue: nil, purchasePrice: 10000)
        #expect(result == nil)
    }

    @Test func appreciationPercent_nilPurchasePrice() {
        let result = ValueTrackingService.appreciationPercent(currentValue: 12000, purchasePrice: nil)
        #expect(result == nil)
    }

    @Test func appreciationPercent_zeroPurchasePrice() {
        let result = ValueTrackingService.appreciationPercent(currentValue: 12000, purchasePrice: 0)
        #expect(result == nil)
    }

    // MARK: - totalCollectionValue

    @Test func totalCollectionValue_multipleWatches() {
        let w1 = Watch(brand: "Rolex", modelName: "Sub")
        w1.currentValue = 15000
        let w2 = Watch(brand: "Omega", modelName: "Speedy")
        w2.currentValue = 8000
        let w3 = Watch(brand: "Seiko", modelName: "5")
        w3.currentValue = nil

        let total = ValueTrackingService.totalCollectionValue([w1, w2, w3])
        #expect(total == 23000)
    }

    @Test func totalCollectionValue_empty() {
        let total = ValueTrackingService.totalCollectionValue([])
        #expect(total == 0)
    }

    // MARK: - totalAppreciation

    @Test func totalAppreciation_mixed() {
        let w1 = Watch(brand: "Rolex", modelName: "Sub")
        w1.purchasePrice = 10000
        w1.currentValue = 15000

        let w2 = Watch(brand: "Omega", modelName: "Speedy")
        w2.purchasePrice = 8000
        w2.currentValue = 7000

        let total = ValueTrackingService.totalAppreciation([w1, w2])
        #expect(total == 4000) // 5000 + (-1000)
    }

    // MARK: - wearCostPerDay

    @Test func wearCostPerDay_withWearLogs() {
        let watch = Watch(brand: "Rolex", modelName: "Sub")
        watch.currentValue = 15000
        let log1 = WearLog(watch: watch, date: Date())
        let log2 = WearLog(watch: watch, date: Date())
        let log3 = WearLog(watch: watch, date: Date())
        watch.wearLogs = [log1, log2, log3]

        let cost = ValueTrackingService.wearCostPerDay(for: watch)
        #expect(cost == 5000)
    }

    @Test func wearCostPerDay_noWearLogs() {
        let watch = Watch(brand: "Rolex", modelName: "Sub")
        watch.currentValue = 15000
        let cost = ValueTrackingService.wearCostPerDay(for: watch)
        #expect(cost == nil)
    }

    @Test func wearCostPerDay_noCurrentValue() {
        let watch = Watch(brand: "Rolex", modelName: "Sub")
        let log = WearLog(watch: watch, date: Date())
        watch.wearLogs = [log]
        let cost = ValueTrackingService.wearCostPerDay(for: watch)
        #expect(cost == nil)
    }

    // MARK: - valueOverTime

    @Test func valueOverTime_sortedByDate() {
        let watch = Watch(brand: "Rolex", modelName: "Sub")
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let date3 = Date(timeIntervalSince1970: 3000)

        let v1 = ValueHistory(watch: watch, date: date3, value: 15000)
        let v2 = ValueHistory(watch: watch, date: date1, value: 10000)
        let v3 = ValueHistory(watch: watch, date: date2, value: 12000)
        watch.valueHistory = [v1, v2, v3]

        let timeline = ValueTrackingService.valueOverTime(for: watch)
        #expect(timeline.count == 3)
        #expect(timeline[0].1 == 10000)
        #expect(timeline[1].1 == 12000)
        #expect(timeline[2].1 == 15000)
    }
}
