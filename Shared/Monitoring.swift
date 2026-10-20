import Foundation
import DeviceActivity
import FamilyControls
import RewardCore

extension DeviceActivityName {
    static let daily = Self("daily")
}

enum Monitoring {
    /// Registers a repeating midnight-to-midnight schedule with read/spend threshold events.
    static func start(earn: FamilyActivitySelection, spend: FamilyActivitySelection) throws {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for event in EventPlan.events() {
            let selection = event.kind == .read ? earn : spend
            events[DeviceActivityEvent.Name(event.rawValue)] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(hour: event.minutes / 60, minute: event.minutes % 60)
            )
        }
        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
        try center.startMonitoring(.daily, during: schedule, events: events)
    }
}
