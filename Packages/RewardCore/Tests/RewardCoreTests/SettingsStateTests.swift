import XCTest
@testable import RewardCore

final class SettingsStateTests: XCTestCase {
    func testStartsWithDefaultAndNothingPending() {
        let s = SettingsState()
        XCTAssertEqual(s.active, .default)
        XCTAssertNil(s.pending)
    }

    func testStricterRatioAppliesImmediately() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 2, dailyCap: 60))
        XCTAssertEqual(s.active.ratio, 2)
        XCTAssertNil(s.pending)
    }

    func testLooserRatioIsQueued() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 5, dailyCap: 60))
        XCTAssertEqual(s.active.ratio, 3)
        XCTAssertEqual(s.pending, RewardPolicy(ratio: 5, dailyCap: 60))
    }

    func testLowerCapAppliesImmediatelyHigherCapIsQueued() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 3, dailyCap: 30))
        XCTAssertEqual(s.active.dailyCap, 30)
        s.request(RewardPolicy(ratio: 3, dailyCap: 90))
        XCTAssertEqual(s.active.dailyCap, 30)
        XCTAssertEqual(s.pending?.dailyCap, 90)
    }

    func testMixedChangeSplitsFieldByField() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 5, dailyCap: 30))
        XCTAssertEqual(s.active, RewardPolicy(ratio: 3, dailyCap: 30))
        XCTAssertEqual(s.pending, RewardPolicy(ratio: 5, dailyCap: 30))
    }

    func testTurningEnforcementOffIsQueuedTurningOnIsImmediate() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 3, dailyCap: 60, enforced: false))
        XCTAssertTrue(s.active.enforced)
        XCTAssertEqual(s.pending?.enforced, false)

        var off = SettingsState(active: RewardPolicy(ratio: 3, dailyCap: 60, enforced: false))
        off.request(RewardPolicy(ratio: 3, dailyCap: 60, enforced: true))
        XCTAssertTrue(off.active.enforced)
        XCTAssertNil(off.pending)
    }

    func testRequestingCurrentValuesClearsPending() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 5, dailyCap: 60))
        s.request(.default)
        XCTAssertNil(s.pending)
    }

    func testRequestedShowsPendingWhenPresent() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 5, dailyCap: 60))
        XCTAssertEqual(s.requested.ratio, 5)
    }

    func testRollOverPromotesPending() {
        var s = SettingsState()
        s.request(RewardPolicy(ratio: 5, dailyCap: 90))
        s.rollOver()
        XCTAssertEqual(s.active, RewardPolicy(ratio: 5, dailyCap: 90))
        XCTAssertNil(s.pending)
    }

    func testRollOverWithoutPendingChangesNothing() {
        var s = SettingsState(active: RewardPolicy(ratio: 2, dailyCap: 40))
        s.rollOver()
        XCTAssertEqual(s.active, RewardPolicy(ratio: 2, dailyCap: 40))
    }
}
