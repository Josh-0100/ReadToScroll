import FamilyControls
import ManagedSettings
import RewardCore

enum Shielding {
    private static let store = ManagedSettingsStore(named: .init("readtoscroll"))

    static var isShielding: Bool { store.shield.applications?.isEmpty == false }

    /// Shields the spend apps when the balance is empty, otherwise clears the shield.
    static func apply(_ state: AppState, spend: FamilyActivitySelection, reason: String) {
        let was = isShielding
        SharedStore().log("shield \(state.shouldShield ? "ON" : "OFF") (was \(was ? "ON" : "OFF")) via \(reason); emergency=\(state.ledger.activeEmergency.map { "\($0.minutesUsed)/\($0.allowance)" } ?? "none")")
        guard state.shouldShield else {
            store.clearAllSettings()
            return
        }
        store.shield.applications = spend.applicationTokens.isEmpty ? nil : spend.applicationTokens
        store.shield.webDomains = spend.webDomainTokens.isEmpty ? nil : spend.webDomainTokens
    }
}
