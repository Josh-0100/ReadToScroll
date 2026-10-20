import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmingEmergency = false

    var body: some View {
        let state = model.state
        let policy = state.settings.active
        List {
            Section {
                VStack(spacing: 4) {
                    Text("\(state.remainingMinutes)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                    Text("Instagram minutes left today").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            Section("Today") {
                LabeledContent("Read", value: "\(state.ledger.readMinutes) min")
                LabeledContent("Earned", value: "\(state.earnedMinutes) of \(policy.dailyCap) min")
                LabeledContent("Used", value: "\(state.ledger.spentMinutes) min")
            }
            Section("Rules") {
                LabeledContent("1 min reading earns", value: "\(policy.ratio) min")
                LabeledContent("Daily cap", value: "\(policy.dailyCap) min")
                if let pending = state.settings.pending {
                    Label("From tomorrow: \(pending.ratio) min per min, cap \(pending.dailyCap) min, \(pending.emergencyMinutes) min emergency unlocks\(pending.enforced ? "" : ", unlocked")",
                          systemImage: "clock")
                        .foregroundStyle(.orange)
                }
                NavigationLink("Change rules") { SettingsView() }
            }
            Section("Emergency") {
                if let session = state.ledger.activeEmergency {
                    Label("Instagram unlocked: \(session.minutesUsed) of \(session.allowance) min used",
                          systemImage: "lock.open")
                        .foregroundStyle(.red)
                } else {
                    Button("Emergency unlock", role: .destructive) {
                        confirmingEmergency = true
                    }
                    .disabled(!state.shouldShield)
                    if state.ledger.emergenciesUsed > 0 {
                        LabeledContent("Used today", value: "\(state.ledger.emergenciesUsed)")
                    }
                }
            }
            if let error = model.monitoringError {
                Text(error).foregroundStyle(.red)
            }
        }
        .confirmationDialog(
            "Unlock Instagram for \(policy.emergencyMinutes) min?",
            isPresented: $confirmingEmergency,
            titleVisibility: .visible
        ) {
            Button("Unlock Instagram for \(policy.emergencyMinutes) min", role: .destructive) {
                model.startEmergency()
            }
        } message: {
            Text("Doesn't use your earned time. Instagram locks again after \(policy.emergencyMinutes) min of use.")
        }
        .navigationTitle("Read to Scroll")
        .refreshable { model.refresh() }
    }
}
