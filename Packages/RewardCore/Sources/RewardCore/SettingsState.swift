/// The active policy plus any looser change waiting for the next day.
public struct SettingsState: Codable, Equatable, Sendable {
    public private(set) var active: RewardPolicy
    public private(set) var pending: RewardPolicy?

    public init(active: RewardPolicy = .default, pending: RewardPolicy? = nil) {
        self.active = active
        self.pending = pending
    }

    /// The latest values the user asked for (what the settings screen shows).
    public var requested: RewardPolicy { pending ?? active }

    /// Stricter parts of `desired` apply now; looser parts wait for `rollOver()`.
    public mutating func request(_ desired: RewardPolicy) {
        let now = RewardPolicy(
            ratio: min(active.ratio, desired.ratio),
            dailyCap: min(active.dailyCap, desired.dailyCap),
            enforced: active.enforced || desired.enforced,
            emergencyUnlocks: min(active.emergencyUnlocks, desired.emergencyUnlocks),
            emergencyMinutes: min(active.emergencyMinutes, desired.emergencyMinutes)
        )
        active = now
        pending = desired == now ? nil : desired
    }

    /// Called once when a new day starts.
    public mutating func rollOver() {
        guard let pending else { return }
        active = pending
        self.pending = nil
    }
}
