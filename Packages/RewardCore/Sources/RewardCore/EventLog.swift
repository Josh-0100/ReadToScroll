/// Bounded debug log written by the monitor extension and shown in the app.
public struct EventLog: Codable, Equatable, Sendable {
    public static let capacity = 200
    public private(set) var entries: [String] = []

    public init() {}

    public mutating func append(_ line: String) {
        entries.append(line)
        if entries.count > Self.capacity {
            entries.removeFirst(entries.count - Self.capacity)
        }
    }
}
