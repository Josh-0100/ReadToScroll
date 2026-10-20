import XCTest
@testable import RewardCore

final class EmergencyTests: XCTestCase {
    private let day = "2026-10-20"

    func testDefaultsAreTwoUnlocksOfFiveMinutes() {
        XCTAssertEqual(RewardPolicy.default.emergencyUnlocks, 2)
        XCTAssertEqual(RewardPolicy.default.emergencyMinutes, 5)
    }

    func testEmergencySettingsAreClamped() {
        let p = RewardPolicy(ratio: 3, dailyCap: 60, emergencyUnlocks: 9, emergencyMinutes: 0)
        XCTAssertEqual(p.emergencyUnlocks, 5)
        XCTAssertEqual(p.emergencyMinutes, 1)
    }

    func testLegacyJSONWithoutEmergencyFieldsDecodesWithDefaults() throws {
        let json = #"{"settings":{"active":{"enforced":true,"dailyCap":60,"ratio":3}},"ledger":{"readMinutes":4,"day":"2026-10-20","spentMinutes":1}}"#
        let s = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        XCTAssertEqual(s.settings.active.emergencyUnlocks, 2)
        XCTAssertEqual(s.ledger.readMinutes, 4)
        XCTAssertEqual(s.ledger.emergenciesUsed, 0)
        XCTAssertNil(s.ledger.activeEmergency)
    }

    func testFewerUnlocksApplyNowMoreAreQueued() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 3, dailyCap: 60, emergencyUnlocks: 1, emergencyMinutes: 10))
        XCTAssertEqual(s.active.emergencyUnlocks, 1)
        XCTAssertEqual(s.active.emergencyMinutes, 5)
        XCTAssertEqual(s.pending?.emergencyMinutes, 10)
    }

    func testStartingAnEmergencyUnshieldsAndUsesOneUnlock() {
        var s = AppState(day: day)
        XCTAssertTrue(s.startEmergency())
        XCTAssertFalse(s.shouldShield)
        XCTAssertEqual(s.emergenciesLeft, 1)
        XCTAssertEqual(s.ledger.activeEmergency, EmergencySession(minutesUsed: 0, allowance: 5))
    }

    func testCannotStartWhileOneIsActiveOrNoneLeft() {
        var s = AppState(day: day)
        XCTAssertTrue(s.startEmergency())
        XCTAssertFalse(s.startEmergency())
        s.endEmergency()
        XCTAssertTrue(s.startEmergency())
        s.endEmergency()
        XCTAssertFalse(s.startEmergency())
        XCTAssertEqual(s.emergenciesLeft, 0)
    }

    func testZeroUnlocksSettingAllowsNone() {
        var s = AppState(day: day, settings: SettingsState(active: RewardPolicy(ratio: 3, dailyCap: 60, emergencyUnlocks: 0)))
        XCTAssertFalse(s.startEmergency())
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

    func testCancelRefundsTheUnlock() {
        var s = AppState(day: day)
        s.startEmergency()
        s.cancelEmergency()
        XCTAssertEqual(s.emergenciesLeft, 2)
        XCTAssertNil(s.ledger.activeEmergency)
        XCTAssertTrue(s.shouldShield)
    }

    func testNewDayResetsUnlocks() {
        var s = AppState(day: day)
        s.startEmergency()
        s.advance(to: "2026-10-21")
        XCTAssertEqual(s.emergenciesLeft, 2)
        XCTAssertNil(s.ledger.activeEmergency)
    }

    func testEmergencyEventNamesAndPlan() {
        XCTAssertEqual(EventName(rawValue: "emergency.3"), EventName(kind: .emergency, minutes: 3))
        XCTAssertEqual(EventPlan.emergencyEvents().map(\.minutes), Array(1...15))
        XCTAssertFalse(EventPlan.events().contains { $0.kind == .emergency })
    }

    func testShieldCopyMentionsUnlocksLeft() {
        let s = AppState(day: day)
        XCTAssertEqual(ShieldCopy.make(for: s).subtitle,
                       "Read 1 min in Apple Books to earn 3 min.\nEmergency? 2 unlocks left in the app.")
    }

    func testShieldCopyOmitsEmergencyLineWhenNoneLeft() {
        let s = AppState(day: day, settings: SettingsState(active: RewardPolicy(ratio: 3, dailyCap: 60, emergencyUnlocks: 0)))
        XCTAssertEqual(ShieldCopy.make(for: s).subtitle, "Read 1 min in Apple Books to earn 3 min.")
    }
}
