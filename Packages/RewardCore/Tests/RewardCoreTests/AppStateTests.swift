import XCTest
@testable import RewardCore

final class AppStateTests: XCTestCase {
    private let day = "2026-10-20"

    func testNewDayHasNoBalanceAndShields() {
        let s = AppState(day: day)
        XCTAssertEqual(s.remainingMinutes, 0)
        XCTAssertTrue(s.shouldShield)
    }

    func testReadingEarnsAndUnshields() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 2))
        XCTAssertEqual(s.earnedMinutes, 6)
        XCTAssertEqual(s.remainingMinutes, 6)
        XCTAssertFalse(s.shouldShield)
    }

    func testSpendingAllEarnedTimeShields() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 1))
        s.record(EventName(kind: .spend, minutes: 3))
        XCTAssertEqual(s.remainingMinutes, 0)
        XCTAssertTrue(s.shouldShield)
    }

    func testCapLoweredBelowSpentClampsToZeroAndShields() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 20))
        s.record(EventName(kind: .spend, minutes: 40))
        s.settings.request(RewardPolicy(ratio: 3, dailyCap: 30))
        XCTAssertEqual(s.remainingMinutes, 0)
        XCTAssertTrue(s.shouldShield)
    }

    func testEnforcementOffNeverShields() {
        let s = AppState(day: day, settings: SettingsState(active: RewardPolicy(ratio: 3, dailyCap: 60, enforced: false)))
        XCTAssertFalse(s.shouldShield)
    }

    func testAdvanceToSameDayKeepsLedger() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 4))
        s.advance(to: day)
        XCTAssertEqual(s.ledger.readMinutes, 4)
    }

    func testAdvanceToNextDayResetsLedgerAndAppliesPending() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 4))
        s.settings.request(RewardPolicy(ratio: 5, dailyCap: 60))
        s.advance(to: "2026-10-21")
        XCTAssertEqual(s.ledger.day, "2026-10-21")
        XCTAssertEqual(s.ledger.readMinutes, 0)
        XCTAssertEqual(s.settings.active.ratio, 5)
        XCTAssertNil(s.settings.pending)
    }

    func testAdvanceAcrossSeveralSkippedDaysAppliesPendingOnce() {
        var s = AppState(day: day)
        s.settings.request(RewardPolicy(ratio: 5, dailyCap: 60))
        s.advance(to: "2026-10-25")
        XCTAssertEqual(s.ledger.day, "2026-10-25")
        XCTAssertEqual(s.settings.active.ratio, 5)
        XCTAssertNil(s.settings.pending)
    }

    func testAdvanceBackwardsIsIgnored() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 4))
        s.advance(to: "2026-10-19")
        XCTAssertEqual(s.ledger.day, day)
        XCTAssertEqual(s.ledger.readMinutes, 4)
    }

    func testRoundTripsThroughJSON() throws {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 2))
        s.settings.request(RewardPolicy(ratio: 6, dailyCap: 60))
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(AppState.self, from: data), s)
    }
}
