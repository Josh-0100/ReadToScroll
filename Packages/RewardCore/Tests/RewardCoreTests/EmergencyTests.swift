import XCTest
@testable import RewardCore

final class EmergencyTests: XCTestCase {
    private let day = "2026-10-20"

    func testDefaultUnlockIsFiveMinutes() {
        XCTAssertEqual(RewardPolicy.default.emergencyMinutes, 5)
    }

    func testEmergencyMinutesAreClamped() {
        XCTAssertEqual(RewardPolicy(ratio: 3, dailyCap: 60, emergencyMinutes: 0).emergencyMinutes, 1)
        XCTAssertEqual(RewardPolicy(ratio: 3, dailyCap: 60, emergencyMinutes: 99).emergencyMinutes, 15)
    }

    func testLegacyJSONWithoutEmergencyFieldsDecodesWithDefaults() throws {
        let json = #"{"settings":{"active":{"enforced":true,"dailyCap":60,"ratio":3}},"ledger":{"readMinutes":4,"day":"2026-10-20","spentMinutes":1}}"#
        let s = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        XCTAssertEqual(s.settings.active.emergencyMinutes, 5)
        XCTAssertEqual(s.ledger.readMinutes, 4)
        XCTAssertEqual(s.ledger.emergenciesUsed, 0)
        XCTAssertNil(s.ledger.activeEmergency)
    }

    func testJSONFromLimitedUnlockBuildStillDecodes() throws {
        let json = #"{"settings":{"active":{"emergencyUnlocks":2,"ratio":3,"dailyCap":60,"enforced":true,"emergencyMinutes":5}},"ledger":{"spentMinutes":6,"emergenciesUsed":1,"emergencyMinutesUsed":0,"activeEmergency":{"allowance":5,"minutesUsed":0},"readMinutes":2,"day":"2026-10-20"}}"#
        let s = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        XCTAssertEqual(s.ledger.activeEmergency, EmergencySession(minutesUsed: 0, allowance: 5))
        XCTAssertFalse(s.shouldShield)
    }

    func testShorterUnlockAppliesNowLongerIsQueued() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 3, dailyCap: 60, emergencyMinutes: 3))
        XCTAssertEqual(s.active.emergencyMinutes, 3)
        s.request(RewardPolicy(ratio: 3, dailyCap: 60, emergencyMinutes: 10))
        XCTAssertEqual(s.active.emergencyMinutes, 3)
        XCTAssertEqual(s.pending?.emergencyMinutes, 10)
    }

    func testStartingAnEmergencyUnshieldsAndCountsIt() {
        var s = AppState(day: day)
        XCTAssertTrue(s.startEmergency())
        XCTAssertFalse(s.shouldShield)
        XCTAssertEqual(s.ledger.emergenciesUsed, 1)
        XCTAssertEqual(s.ledger.activeEmergency, EmergencySession(minutesUsed: 0, allowance: 5))
    }

    func testCannotStartWhileOneIsActive() {
        var s = AppState(day: day)
        XCTAssertTrue(s.startEmergency())
        XCTAssertFalse(s.startEmergency())
        XCTAssertEqual(s.ledger.emergenciesUsed, 1)
    }

    func testNoDailyLimitOnUnlocks() {
        var s = AppState(day: day)
        for _ in 1...10 {
            XCTAssertTrue(s.startEmergency())
            s.endEmergency()
        }
        XCTAssertEqual(s.ledger.emergenciesUsed, 10)
    }

    func testReachingAllowanceEndsEmergencyAndReshields() {
        var s = AppState(day: day)
        s.startEmergency()
        s.record(EventName(kind: .emergency, minutes: 4))
        XCTAssertFalse(s.shouldShield)
        s.record(EventName(kind: .emergency, minutes: 5))
        XCTAssertNil(s.ledger.activeEmergency)
        XCTAssertTrue(s.shouldShield)
    }

    func testEmergencyMinutesDoNotConsumeEarnedBalance() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 2))     // earned 6
        s.startEmergency()
        s.record(EventName(kind: .spend, minutes: 5))    // daily spend events also fire during the emergency
        s.record(EventName(kind: .emergency, minutes: 5))
        XCTAssertEqual(s.remainingMinutes, 6)
        XCTAssertFalse(s.shouldShield)
    }

    func testWindowEndingEarlyKeepsPartialMinutesExcluded() {
        var s = AppState(day: day)
        s.record(EventName(kind: .read, minutes: 2))
        s.startEmergency()
        s.record(EventName(kind: .spend, minutes: 2))
        s.record(EventName(kind: .emergency, minutes: 2))
        s.endEmergency()
        XCTAssertEqual(s.remainingMinutes, 6)
    }

    func testEmergencyEventWithoutActiveSessionIsIgnored() {
        var s = AppState(day: day)
        s.record(EventName(kind: .emergency, minutes: 3))
        XCTAssertEqual(s.ledger.emergencyMinutesUsed, 0)
    }

    func testCancelUndoesTheStart() {
        var s = AppState(day: day)
        s.startEmergency()
        s.cancelEmergency()
        XCTAssertEqual(s.ledger.emergenciesUsed, 0)
        XCTAssertNil(s.ledger.activeEmergency)
        XCTAssertTrue(s.shouldShield)
    }

    func testNewDayClearsActiveUnlockAndCount() {
        var s = AppState(day: day)
        s.startEmergency()
        s.advance(to: "2026-10-21")
        XCTAssertEqual(s.ledger.emergenciesUsed, 0)
        XCTAssertNil(s.ledger.activeEmergency)
    }

    func testEmergencyEventNamesAndPlan() {
        XCTAssertEqual(EventName(rawValue: "emergency.3"), EventName(kind: .emergency, minutes: 3))
        XCTAssertEqual(EventPlan.emergencyEvents().map(\.minutes), Array(1...15))
        XCTAssertFalse(EventPlan.events().contains { $0.kind == .emergency })
    }

    func testShieldCopyPointsToEmergencyUnlock() {
        XCTAssertEqual(ShieldCopy.make(for: AppState(day: day)).subtitle,
                       "Read 1 min in Apple Books to earn 3 min.\nNeed messages? Emergency unlock in the app.")
    }
}
