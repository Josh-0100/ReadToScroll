import XCTest
@testable import RewardCore

final class EventLogTests: XCTestCase {
    func testAppendsInOrder() {
        var log = EventLog()
        log.append("a"); log.append("b")
        XCTAssertEqual(log.entries, ["a", "b"])
    }

    func testDropsOldestBeyondCapacity() {
        var log = EventLog()
        for i in 0..<(EventLog.capacity + 5) { log.append("\(i)") }
        XCTAssertEqual(log.entries.count, EventLog.capacity)
        XCTAssertEqual(log.entries.first, "5")
    }
}
