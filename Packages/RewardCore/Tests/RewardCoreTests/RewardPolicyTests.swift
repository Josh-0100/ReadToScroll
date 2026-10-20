import XCTest
@testable import RewardCore

final class RewardPolicyTests: XCTestCase {
    func testDefaultIsThreeToOneWithSixtyMinuteCap() {
        XCTAssertEqual(RewardPolicy.default, RewardPolicy(ratio: 3, dailyCap: 60, enforced: true))
    }

    func testEarnedMultipliesReadingByRatio() {
        XCTAssertEqual(RewardPolicy(ratio: 3, dailyCap: 60).earned(readMinutes: 5), 15)
    }

    func testEarnedIsCappedAtDailyCap() {
        XCTAssertEqual(RewardPolicy(ratio: 3, dailyCap: 60).earned(readMinutes: 25), 60)
    }

    func testEarnedTreatsNegativeReadingAsZero() {
        XCTAssertEqual(RewardPolicy(ratio: 3, dailyCap: 60).earned(readMinutes: -4), 0)
    }

    func testInitClampsOutOfRangeValues() {
        let low = RewardPolicy(ratio: 0, dailyCap: 1)
        XCTAssertEqual(low.ratio, 1)
        XCTAssertEqual(low.dailyCap, 10)
        let high = RewardPolicy(ratio: 99, dailyCap: 999)
        XCTAssertEqual(high.ratio, 10)
        XCTAssertEqual(high.dailyCap, 120)
    }

    func testRoundTripsThroughJSON() throws {
        let p = RewardPolicy(ratio: 4, dailyCap: 45, enforced: false)
        let data = try JSONEncoder().encode(p)
        XCTAssertEqual(try JSONDecoder().decode(RewardPolicy.self, from: data), p)
    }
}
