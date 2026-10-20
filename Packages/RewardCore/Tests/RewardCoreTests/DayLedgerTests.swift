import XCTest
@testable import RewardCore

final class DayLedgerTests: XCTestCase {
    func testStartsAtZero() {
        let l = DayLedger(day: "2026-10-20")
        XCTAssertEqual(l.readMinutes, 0)
        XCTAssertEqual(l.spentMinutes, 0)
    }

    func testKeepsHighestCumulativeValue() {
        var l = DayLedger(day: "2026-10-20")
        l.recordRead(totalMinutes: 3)
        l.recordRead(totalMinutes: 5)
        XCTAssertEqual(l.readMinutes, 5)
    }

    func testDuplicateAndOutOfOrderEventsDoNotChangeTotal() {
        var l = DayLedger(day: "2026-10-20")
        l.recordSpent(totalMinutes: 7)
        l.recordSpent(totalMinutes: 7)
        l.recordSpent(totalMinutes: 4)
        XCTAssertEqual(l.spentMinutes, 7)
    }
}
