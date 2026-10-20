import FamilyControls
import SwiftUI
import RewardCore

@MainActor
final class AppModel: ObservableObject {
    private let store = SharedStore()

    @Published private(set) var state: AppState
    @Published var earnSelection: FamilyActivitySelection
    @Published var spendSelection: FamilyActivitySelection
    @Published private(set) var isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @Published private(set) var monitoringError: String?

    init() {
        state = store.loadState()
        earnSelection = store.earnSelection
        spendSelection = store.spendSelection
    }

    var setupProblems: [String] {
        SetupCheck.problems(
            earnItemCount: earnSelection.applicationTokens.count + earnSelection.webDomainTokens.count,
            spendItemCount: spendSelection.applicationTokens.count + spendSelection.webDomainTokens.count
        )
    }

    var isMonitoringReady: Bool {
        isAuthorized && setupProblems.isEmpty
            && !store.earnSelection.applicationTokens.isEmpty
            && !store.spendSelection.applicationTokens.isEmpty
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            monitoringError = "Screen Time permission was not granted: \(error.localizedDescription)"
        }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func saveSelectionsAndStart() {
        guard setupProblems.isEmpty else { return }
        store.earnSelection = earnSelection
        store.spendSelection = spendSelection
        do {
            try Monitoring.start(earn: earnSelection, spend: spendSelection)
            monitoringError = nil
            store.log("monitoring started (\(EventPlan.events().count) events)")
        } catch {
            monitoringError = "Couldn't start monitoring: \(error.localizedDescription)"
        }
        refresh()
    }

    /// Re-reads shared state (the extension may have changed it) and re-applies the shield.
    func refresh() {
        state = store.loadState()
        store.save(state)
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        if isAuthorized { Shielding.apply(state, spend: store.spendSelection) }
    }

    func requestPolicy(_ policy: RewardPolicy) {
        state = store.update { $0.settings.request(policy) }
        Shielding.apply(state, spend: store.spendSelection)
    }

    func startEmergency() {
        var started = false
        state = store.update { started = $0.startEmergency() }
        guard started else { return }
        do {
            try Monitoring.startEmergency(spend: store.spendSelection)
            store.log("emergency unlock started (\(state.emergenciesLeft) left today)")
        } catch {
            state = store.update { $0.cancelEmergency() }
            monitoringError = "Couldn't start emergency unlock: \(error.localizedDescription)"
        }
        Shielding.apply(state, spend: store.spendSelection)
    }

    var eventLog: [String] { store.eventLog.entries.reversed() }
}
