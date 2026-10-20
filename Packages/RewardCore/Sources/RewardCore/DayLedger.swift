/// An emergency unlock in progress.
public struct EmergencySession: Codable, Equatable, Sendable {
    public internal(set) var minutesUsed: Int
    public let allowance: Int

    public init(minutesUsed: Int, allowance: Int) {
        self.minutesUsed = minutesUsed
        self.allowance = allowance
    }
}

/// Reading and Instagram minutes for one day.
public struct DayLedger: Codable, Equatable, Sendable {
    public let day: String
    public private(set) var readMinutes = 0
    public private(set) var spentMinutes = 0
    public internal(set) var emergenciesUsed = 0
    /// Instagram minutes used during finished emergency unlocks (excluded from spending).
    public internal(set) var emergencyMinutesUsed = 0
    public internal(set) var activeEmergency: EmergencySession?

    public init(day: String) { self.day = day }

    // Ledgers saved before emergency unlocks existed decode with zeroes.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(String.self, forKey: .day)
        readMinutes = try c.decode(Int.self, forKey: .readMinutes)
        spentMinutes = try c.decode(Int.self, forKey: .spentMinutes)
        emergenciesUsed = try c.decodeIfPresent(Int.self, forKey: .emergenciesUsed) ?? 0
        emergencyMinutesUsed = try c.decodeIfPresent(Int.self, forKey: .emergencyMinutesUsed) ?? 0
        activeEmergency = try c.decodeIfPresent(EmergencySession.self, forKey: .activeEmergency)
    }

    // Threshold events are cumulative, so keep the highest seen:
    // duplicates and out-of-order delivery are harmless.
    public mutating func recordRead(totalMinutes: Int) { readMinutes = max(readMinutes, totalMinutes) }
    public mutating func recordSpent(totalMinutes: Int) { spentMinutes = max(spentMinutes, totalMinutes) }
}
