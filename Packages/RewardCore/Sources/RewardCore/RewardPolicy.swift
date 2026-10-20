/// The rules for earning Instagram time. Values are clamped to the allowed ranges.
public struct RewardPolicy: Codable, Equatable, Sendable {
    public static let ratioRange = 1...10
    public static let capRange = 10...120
    public static let emergencyUnlocksRange = 0...5
    public static let emergencyMinutesRange = 1...15
    public static let `default` = RewardPolicy(ratio: 3, dailyCap: 60, enforced: true)

    /// Instagram minutes earned per minute of reading.
    public let ratio: Int
    /// Most Instagram minutes that can be earned in one day.
    public let dailyCap: Int
    /// When false, Instagram is never shielded.
    public let enforced: Bool
    /// Emergency unlocks allowed per day.
    public let emergencyUnlocks: Int
    /// Minutes of Instagram use each emergency unlock grants.
    public let emergencyMinutes: Int

    public init(ratio: Int, dailyCap: Int, enforced: Bool = true,
                emergencyUnlocks: Int = 2, emergencyMinutes: Int = 5) {
        self.ratio = Self.clamp(ratio, Self.ratioRange)
        self.dailyCap = Self.clamp(dailyCap, Self.capRange)
        self.enforced = enforced
        self.emergencyUnlocks = Self.clamp(emergencyUnlocks, Self.emergencyUnlocksRange)
        self.emergencyMinutes = Self.clamp(emergencyMinutes, Self.emergencyMinutesRange)
    }

    // Policies saved before emergency unlocks existed decode with the defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            ratio: try c.decode(Int.self, forKey: .ratio),
            dailyCap: try c.decode(Int.self, forKey: .dailyCap),
            enforced: try c.decode(Bool.self, forKey: .enforced),
            emergencyUnlocks: try c.decodeIfPresent(Int.self, forKey: .emergencyUnlocks) ?? 2,
            emergencyMinutes: try c.decodeIfPresent(Int.self, forKey: .emergencyMinutes) ?? 5
        )
    }

    public func earned(readMinutes: Int) -> Int {
        min(max(readMinutes, 0) * ratio, dailyCap)
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
