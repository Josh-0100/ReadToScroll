/// Reading and Instagram minutes for one day.
public struct DayLedger: Codable, Equatable, Sendable {
    public let day: String
    public private(set) var readMinutes = 0
    public private(set) var spentMinutes = 0

    public init(day: String) { self.day = day }

    // Threshold events are cumulative, so keep the highest seen:
    // duplicates and out-of-order delivery are harmless.
    public mutating func recordRead(totalMinutes: Int) { readMinutes = max(readMinutes, totalMinutes) }
    public mutating func recordSpent(totalMinutes: Int) { spentMinutes = max(spentMinutes, totalMinutes) }
}
