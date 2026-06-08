import Testing
import Foundation
@testable import calorietracker

struct StoreManagerSavingsTests {

    @Test func yearlyVsMonthlyComputesRoundedPercent() {
        // 4.99 * 12 = 59.88 ; 1 - 29.99/59.88 = 0.4992 -> 50
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: 4.99, weekly: 1.99) == 50)
    }

    @Test func fallsBackToWeeklyWhenNoMonthly() {
        // 1.99 * 52 = 103.48 ; 1 - 29.99/103.48 = 0.7102 -> 71
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: nil, weekly: 1.99) == 71)
    }

    @Test func nilWhenNoBaselinePrices() {
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: nil, weekly: nil) == nil)
    }

    @Test func nilWhenSavingsNotPositive() {
        // yearly (60) costs more than monthly annualized (59.88) -> negative -> nil
        #expect(StoreManager.savingsPercent(yearly: 60, monthly: 4.99, weekly: nil) == nil)
    }

    @Test func nilWhenYearlyNotPositive() {
        #expect(StoreManager.savingsPercent(yearly: 0, monthly: 4.99, weekly: nil) == nil)
    }

    @Test func monthlyTakesPrecedenceOverWeekly() {
        // monthly path (50) is chosen even though a weekly price is also provided
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: 4.99, weekly: 9.99) == 50)
    }

    @Test func smallPositiveSavingsRoundsToAtLeastOne() {
        // ~0.6% positive savings (4.99*12 = 59.88 baseline) rounds up to 1
        #expect(StoreManager.savingsPercent(yearly: 59.5, monthly: 4.99, weekly: nil) == 1)
    }
}
