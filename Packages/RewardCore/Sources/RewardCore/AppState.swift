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
        case .emergency: recordEmergencyUsage(totalMinutes: event.minutes)
        }
    }

    public var earnedMinutes: Int { settings.active.earned(readMinutes: ledger.readMinutes) }

    /// Instagram minutes that count against the earned balance (emergency use excluded).
    public var countedSpentMinutes: Int {
        let emergency = ledger.emergencyMinutesUsed + (ledger.activeEmergency?.minutesUsed ?? 0)
        return max(0, ledger.spentMinutes - emergency)
    }

    public var remainingMinutes: Int { max(0, earnedMinutes - countedSpentMinutes) }

    public var shouldShield: Bool {
        settings.active.enforced && remainingMinutes == 0 && ledger.activeEmergency == nil
    }

    // MARK: Emergency unlocks

    public var emergenciesLeft: Int { max(0, settings.active.emergencyUnlocks - ledger.emergenciesUsed) }

    /// Uses one unlock. Returns false when one is already active or none are left.
    @discardableResult
    public mutating func startEmergency() -> Bool {
        guard ledger.activeEmergency == nil, emergenciesLeft > 0 else { return false }
        ledger.emergenciesUsed += 1
        ledger.activeEmergency = EmergencySession(minutesUsed: 0, allowance: settings.active.emergencyMinutes)
        return true
    }

    /// Ends the active unlock, keeping the minutes it used excluded from spending.
    public mutating func endEmergency() {
        guard let session = ledger.activeEmergency else { return }
        ledger.emergencyMinutesUsed += session.minutesUsed
        ledger.activeEmergency = nil
    }

    /// Undoes a start that couldn't be put into effect (refunds the unlock).
    public mutating func cancelEmergency() {
        guard ledger.activeEmergency != nil else { return }
        ledger.activeEmergency = nil
        ledger.emergenciesUsed -= 1
    }

    private mutating func recordEmergencyUsage(totalMinutes: Int) {
        guard var session = ledger.activeEmergency else { return }
        session.minutesUsed = max(session.minutesUsed, min(totalMinutes, session.allowance))
        ledger.activeEmergency = session
        if session.minutesUsed >= session.allowance { endEmergency() }
    }
}
