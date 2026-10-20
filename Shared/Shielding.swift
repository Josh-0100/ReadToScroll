import FamilyControls
import ManagedSettings
import RewardCore

enum Shielding {
    private static let store = ManagedSettingsStore(named: .init("readtoscroll"))

    /// Shields the spend apps when the balance is empty, otherwise clears the shield.
    static func apply(_ state: AppState, spend: FamilyActivitySelection) {
        guard state.shouldShield else {
            store.clearAllSettings()
            return
        }
        store.shield.applications = spend.applicationTokens.isEmpty ? nil : spend.applicationTokens
        store.shield.webDomains = spend.webDomainTokens.isEmpty ? nil : spend.webDomainTokens
    }
}
