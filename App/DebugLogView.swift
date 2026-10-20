import SwiftUI

struct DebugLogView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List(model.eventLog, id: \.self) { line in
            Text(line).font(.caption.monospaced())
        }
        .navigationTitle("Event log")
        .refreshable { model.refresh() }
    }
}
