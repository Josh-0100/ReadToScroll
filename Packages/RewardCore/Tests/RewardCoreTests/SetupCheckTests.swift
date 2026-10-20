import XCTest
@testable import RewardCore

final class SetupCheckTests: XCTestCase {
    func testNoProblemsWhenBothPicked() {
        XCTAssertEqual(SetupCheck.problems(earnItemCount: 1, spendItemCount: 1), [])
    }

    func testReportsEachMissingPick() {
        XCTAssertEqual(SetupCheck.problems(earnItemCount: 0, spendItemCount: 0), [
            "Pick Apple Books as your reading app.",
            "Pick Instagram as the app to lock.",
        ])
    }
}
