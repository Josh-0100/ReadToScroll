import XCTest
@testable import RewardCore

final class EventNameTests: XCTestCase {
    func testRawValueRoundTrip() {
        let e = EventName(kind: .spend, minutes: 12)
        XCTAssertEqual(e.rawValue, "spend.12")
        XCTAssertEqual(EventName(rawValue: "spend.12"), e)
    }

    func testRejectsMalformedNames() {
        XCTAssertNil(EventName(rawValue: "spend"))
        XCTAssertNil(EventName(rawValue: "nap.3"))
        XCTAssertNil(EventName(rawValue: "read.x"))
        XCTAssertNil(EventName(rawValue: "read.0"))
        XCTAssertNil(EventName(rawValue: "read.3.4"))
    }

    func testPlanCoversUpperBoundOfSettingsForBothKinds() {
        let events = EventPlan.events(step: 1)
        XCTAssertEqual(events.filter { $0.kind == .read }.count, 120)
        XCTAssertEqual(events.filter { $0.kind == .spend }.count, 120)
        XCTAssertTrue(events.contains(EventName(kind: .read, minutes: 1)))
        XCTAssertTrue(events.contains(EventName(kind: .spend, minutes: 120)))
    }

    func testPlanWithLargerStepSkipsMinutes() {
        let reads = EventPlan.events(step: 2).filter { $0.kind == .read }.map(\.minutes)
        XCTAssertEqual(reads.prefix(3), [2, 4, 6])
        XCTAssertEqual(reads.last, 120)
    }
}
