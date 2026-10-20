import Foundation
import DeviceActivity
import FamilyControls
import RewardCore

extension DeviceActivityName {
    static let daily = Self("daily")
    static let emergency = Self("emergency")
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

    /// One-shot window for an emergency unlock: per-minute Instagram events re-lock when the
    /// allowance is used. iOS requires at least 15 minutes, so the window is 16.
    static func startEmergency(spend: FamilyActivitySelection) throws {
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let now = Date.now
        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents(components, from: now),
            intervalEnd: Calendar.current.dateComponents(components, from: now.addingTimeInterval(16 * 60)),
            repeats: false
        )
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for event in EventPlan.emergencyEvents() {
            events[DeviceActivityEvent.Name(event.rawValue)] = DeviceActivityEvent(
                applications: spend.applicationTokens,
                categories: spend.categoryTokens,
                webDomains: spend.webDomainTokens,
                threshold: DateComponents(minute: event.minutes)
            )
        }
        let center = DeviceActivityCenter()
        center.stopMonitoring([.emergency])
        try center.startMonitoring(.emergency, during: schedule, events: events)
    }
}
