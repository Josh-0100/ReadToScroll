import DeviceActivity
import FamilyControls
import SwiftUI

struct DebugLogView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List {
            Section("Now") {
                LabeledContent("Authorization", value: "\(AuthorizationCenter.shared.authorizationStatus)")
                LabeledContent("Monitoring", value: DeviceActivityCenter().activities.map(\.rawValue).sorted().joined(separator: ", "))
                LabeledContent("Shield", value: Shielding.isShielding ? "ON" : "OFF")
            }
            Section("Log") {
                ForEach(model.eventLog, id: \.self) { line in
                    Text(line).font(.caption.monospaced())
                }
            }
        }
        .navigationTitle("Event log")
        .refreshable { model.refresh() }
    }
}
