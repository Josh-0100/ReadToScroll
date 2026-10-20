import XCTest
@testable import RewardCore

final class ShieldCopyTests: XCTestCase {
    func testOutOfTimeTellsYouHowMuchOneMinuteEarns() {
        let copy = ShieldCopy.make(for: AppState(day: "2026-10-20"))
        XCTAssertEqual(copy.title, "Out of Instagram time")
        XCTAssertEqual(copy.subtitle, "Read 1 min in Apple Books to earn 3 min.\nNeed messages? Emergency unlock in the app.")
    }

    func testNearCapOnlyPromisesWhatIsLeftUnderCap() {
        var s = AppState(day: "2026-10-20")
        s.record(EventName(kind: .read, minutes: 19))   // earned 57 of 60
        s.record(EventName(kind: .spend, minutes: 57))
        XCTAssertEqual(ShieldCopy.make(for: s).subtitle, "Read 1 min in Apple Books to earn 3 min.\nNeed messages? Emergency unlock in the app.")
        s.settings.request(RewardPolicy(ratio: 3, dailyCap: 58))  // 1 left under cap
        XCTAssertEqual(ShieldCopy.make(for: s).subtitle, "Read 1 min in Apple Books to earn 1 min.\nNeed messages? Emergency unlock in the app.")
    }

    func testCapReachedSaysComeBackTomorrow() {
        var s = AppState(day: "2026-10-20")
        s.record(EventName(kind: .read, minutes: 20))
        s.record(EventName(kind: .spend, minutes: 60))
        let copy = ShieldCopy.make(for: s)
        XCTAssertEqual(copy.title, "Daily limit reached")
        XCTAssertEqual(copy.subtitle, "You've used all 60 min for today. Back tomorrow.\nNeed messages? Emergency unlock in the app.")
    }
}
