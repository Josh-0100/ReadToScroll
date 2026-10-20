import DeviceActivity
import RewardCore

final class ReadToScrollMonitor: DeviceActivityMonitor {
    private let store = SharedStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // loadState() inside update rolls over to today: resets ledger, applies queued settings.
        let state = store.update { _ in }
        store.log("new day \(state.ledger.day) ratio \(state.settings.active.ratio) cap \(state.settings.active.dailyCap)")
        Shielding.apply(state, spend: store.spendSelection)
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard let name = EventName(rawValue: event.rawValue) else {
            store.log("unknown event \(event.rawValue)")
            return
        }
        let state = store.update { $0.record(name) }
        store.log("\(name.rawValue) → earned \(state.earnedMinutes) spent \(state.ledger.spentMinutes) left \(state.remainingMinutes)")
        Shielding.apply(state, spend: store.spendSelection)
    }
}
