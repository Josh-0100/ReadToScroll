import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: AppModel

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
            }
            if let error = model.monitoringError {
                Text(error).foregroundStyle(.red)
            }
        }
        .navigationTitle("Read to Scroll")
        .refreshable { model.refresh() }
    }
}
