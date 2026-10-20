/// Name of a DeviceActivity threshold event, encoded as "read.5", "spend.12" or "emergency.3".
public struct EventName: Hashable, Sendable {
    public enum Kind: String, Sendable { case read, spend, emergency }

    public let kind: Kind
    public let minutes: Int

    public init(kind: Kind, minutes: Int) {
        self.kind = kind
        self.minutes = minutes
    }

    public init?(rawValue: String) {
        let parts = rawValue.split(separator: ".")
        guard parts.count == 2,
              let kind = Kind(rawValue: String(parts[0])),
              let minutes = Int(parts[1]), minutes > 0 else { return nil }
        self.init(kind: kind, minutes: minutes)
    }

    public var rawValue: String { "\(kind.rawValue).\(minutes)" }
}

public enum Tuning {
    /// Minutes between threshold events. Set by the on-device spike (Task 6).
    public static let thresholdStep = 1
}

public enum EventPlan {
    /// Events are registered once for the widest allowed settings (cap 120, ratio 1),
    /// so changing ratio/cap never requires re-registering mid-day.
    public static func events(step: Int = Tuning.thresholdStep) -> [EventName] {
        let maxMinutes = RewardPolicy.capRange.upperBound
        let minutes = Array(stride(from: step, through: maxMinutes, by: step))
        return minutes.map { EventName(kind: .read, minutes: $0) }
            + minutes.map { EventName(kind: .spend, minutes: $0) }
    }

    /// Per-minute events for an emergency window, covering the largest allowed unlock.
    public static func emergencyEvents() -> [EventName] {
        RewardPolicy.emergencyMinutesRange.map { EventName(kind: .emergency, minutes: $0) }
    }
}
