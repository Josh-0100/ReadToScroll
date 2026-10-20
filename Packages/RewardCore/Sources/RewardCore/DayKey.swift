import Foundation

/// A sortable local-calendar day identifier, e.g. "2026-10-20".
public enum DayKey {
    public static func string(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
