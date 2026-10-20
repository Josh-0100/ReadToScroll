/// The rules for earning Instagram time. Values are clamped to the allowed ranges.
public struct RewardPolicy: Codable, Equatable, Sendable {
    public static let ratioRange = 1...10
    public static let capRange = 10...120
    public static let `default` = RewardPolicy(ratio: 3, dailyCap: 60, enforced: true)

    /// Instagram minutes earned per minute of reading.
    public let ratio: Int
    /// Most Instagram minutes that can be earned in one day.
    public let dailyCap: Int
    /// When false, Instagram is never shielded.
    public let enforced: Bool

    public init(ratio: Int, dailyCap: Int, enforced: Bool = true) {
        self.ratio = min(max(ratio, Self.ratioRange.lowerBound), Self.ratioRange.upperBound)
        self.dailyCap = min(max(dailyCap, Self.capRange.lowerBound), Self.capRange.upperBound)
        self.enforced = enforced
    }

    public func earned(readMinutes: Int) -> Int {
        min(max(readMinutes, 0) * ratio, dailyCap)
    }
}
