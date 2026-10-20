import FamilyControls
import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pickingEarn = false
    @State private var pickingSpend = false

    var body: some View {
        Form {
            Section("1. Permission") {
                if model.isAuthorized {
                    Label("Screen Time access granted", systemImage: "checkmark.circle.fill")
                } else {
                    Button("Allow Screen Time access") {
                        Task { await model.requestAuthorization() }
                    }
                }
            }
            Section("2. Reading app") {
                Button(model.earnSelection.applicationTokens.isEmpty ? "Choose Apple Books" : "Apple Books chosen ✓") {
                    pickingEarn = true
                }
                .disabled(!model.isAuthorized)
            }
            Section("3. App to lock") {
                Button(model.spendSelection.applicationTokens.isEmpty ? "Choose Instagram" : "Instagram chosen ✓") {
                    pickingSpend = true
                }
                .disabled(!model.isAuthorized)
            }
            Section {
                ForEach(model.setupProblems, id: \.self) { Text($0).foregroundStyle(.secondary) }
                Button("Start") { model.saveSelectionsAndStart() }
                    .disabled(!model.isAuthorized || !model.setupProblems.isEmpty)
                if let error = model.monitoringError {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Set up")
        .familyActivityPicker(isPresented: $pickingEarn, selection: $model.earnSelection)
        .familyActivityPicker(isPresented: $pickingSpend, selection: $model.spendSelection)
    }
}
