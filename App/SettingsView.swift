import SwiftUI
import RewardCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var ratio = RewardPolicy.default.ratio
    @State private var cap = RewardPolicy.default.dailyCap
    @State private var enforced = true
    @State private var emergencyMinutes = RewardPolicy.default.emergencyMinutes

    private var draft: RewardPolicy {
        RewardPolicy(ratio: ratio, dailyCap: cap, enforced: enforced,
                     emergencyMinutes: emergencyMinutes)
    }

    var body: some View {
        Form {
            Section {
                Stepper("1 min reading = \(ratio) min Instagram", value: $ratio, in: RewardPolicy.ratioRange)
                Stepper("Daily cap: \(cap) min", value: $cap, in: RewardPolicy.capRange, step: 5)
                Toggle("Lock Instagram", isOn: $enforced)
                Stepper("Emergency unlock: \(emergencyMinutes) min", value: $emergencyMinutes,
                        in: RewardPolicy.emergencyMinutesRange)
            } footer: {
                Text("Stricter changes apply now. Looser changes (higher ratio, higher cap, longer emergency unlocks, unlocking) start tomorrow.")
            }
            Section {
                Button("Save") {
                    model.requestPolicy(draft)
                    dismiss()
                }
                .disabled(draft == model.state.settings.requested)
            }
        }
        .navigationTitle("Rules")
        .onAppear {
            let requested = model.state.settings.requested
            ratio = requested.ratio
            cap = requested.dailyCap
            enforced = requested.enforced
            emergencyMinutes = requested.emergencyMinutes
        }
    }
}
