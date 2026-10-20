import Foundation
import FamilyControls
import RewardCore

enum AppGroup {
    static let id = "group.com.joshhinder.readtoscroll"
}

/// App Group persistence shared by the app and all extensions.
struct SharedStore {
    private let defaults = UserDefaults(suiteName: AppGroup.id)!

    private enum Key {
        static let state = "state.v1"
        static let earn = "earnSelection.v1"
        static let spend = "spendSelection.v1"
        static let log = "log.v1"
    }

    /// Loads state and rolls it forward to today (resetting the ledger / applying queued settings if needed).
    func loadState(now: Date = .now) -> AppState {
        let today = DayKey.string(for: now)
        var state = read(AppState.self, Key.state) ?? AppState(day: today)
        state.advance(to: today)
        return state
    }

    func save(_ state: AppState) { write(state, Key.state) }

    @discardableResult
    func update(now: Date = .now, _ body: (inout AppState) -> Void) -> AppState {
        var state = loadState(now: now)
        body(&state)
        save(state)
        return state
    }

    var earnSelection: FamilyActivitySelection {
        get { read(FamilyActivitySelection.self, Key.earn) ?? FamilyActivitySelection() }
        nonmutating set { write(newValue, Key.earn) }
    }

    var spendSelection: FamilyActivitySelection {
        get { read(FamilyActivitySelection.self, Key.spend) ?? FamilyActivitySelection() }
        nonmutating set { write(newValue, Key.spend) }
    }

    var eventLog: EventLog { read(EventLog.self, Key.log) ?? EventLog() }

    func log(_ line: String) {
        var log = eventLog
        log.append("\(Date.now.formatted(date: .omitted, time: .standard))  \(line)")
        write(log, Key.log)
    }

    private func read<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private func write<T: Encodable>(_ value: T, _ key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
