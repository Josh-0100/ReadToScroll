/// Everything persisted in the App Group: settings plus today's ledger.
public struct AppState: Codable, Equatable, Sendable {
    public var settings: SettingsState
    public private(set) var ledger: DayLedger

    public init(day: String, settings: SettingsState = SettingsState()) {
        self.settings = settings
        self.ledger = DayLedger(day: day)
    }

    /// Call before every read. A later day resets the ledger and applies queued settings once;
    /// an earlier day (clock moved back) is ignored.
    public mutating func advance(to day: String) {
        guard day > ledger.day else { return }
        ledger = DayLedger(day: day)
        settings.rollOver()
    }

    public mutating func record(_ event: EventName) {
        switch event.kind {
        case .read: ledger.recordRead(totalMinutes: event.minutes)
        case .spend: ledger.recordSpent(totalMinutes: event.minutes)
        }
    }

    public var earnedMinutes: Int { settings.active.earned(readMinutes: ledger.readMinutes) }
    public var remainingMinutes: Int { max(0, earnedMinutes - ledger.spentMinutes) }
    public var shouldShield: Bool { settings.active.enforced && remainingMinutes == 0 }
}
