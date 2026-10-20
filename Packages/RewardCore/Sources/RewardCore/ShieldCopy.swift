/// Text for the Instagram block screen.
public struct ShieldCopy: Equatable, Sendable {
    public let title: String
    public let subtitle: String

    public static func make(for state: AppState) -> ShieldCopy {
        let policy = state.settings.active
        let earnable = policy.dailyCap - state.earnedMinutes
        let emergencyLine = "\nNeed messages? Emergency unlock in the app."
        if earnable <= 0 {
            return ShieldCopy(title: "Daily limit reached",
                              subtitle: "You've used all \(policy.dailyCap) min for today. Back tomorrow." + emergencyLine)
        }
        let perMinute = min(policy.ratio, earnable)
        return ShieldCopy(title: "Out of Instagram time",
                          subtitle: "Read 1 min in Apple Books to earn \(perMinute) min." + emergencyLine)
    }
}
