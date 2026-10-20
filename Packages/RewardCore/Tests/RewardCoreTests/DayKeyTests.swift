import XCTest
@testable import RewardCore

final class DayKeyTests: XCTestCase {
    private var london: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        london.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testFormatsAsZeroPaddedLocalDate() {
        XCTAssertEqual(DayKey.string(for: date(2026, 3, 7, 12, 0), calendar: london), "2026-03-07")
    }

    func testOneMinuteBeforeAndAfterMidnightAreDifferentDays() {
        XCTAssertEqual(DayKey.string(for: date(2026, 10, 20, 23, 59), calendar: london), "2026-10-20")
        XCTAssertEqual(DayKey.string(for: date(2026, 10, 21, 0, 0), calendar: london), "2026-10-21")
    }

    func testKeysSortChronologically() {
        XCTAssertLessThan(DayKey.string(for: date(2026, 9, 30, 9, 0), calendar: london),
                          DayKey.string(for: date(2026, 10, 1, 9, 0), calendar: london))
    }
}
