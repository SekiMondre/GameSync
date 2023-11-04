public protocol GameCenterLeaderboardEntry: IntComparable, Equatable, Codable {
    var score: Int { get }
    var gamePlayerID: String { get }
    var isReversed: Bool { get }
    init(leaderboardID: String, gkEntry: GKEntry) async throws
}

extension GameCenterLeaderboardEntry {
    public var intValue: Int { score }
    
    public func ranksHigherThan(_ other: Int) -> Bool {
        if isReversed {
            return score < other
        } else {
            return score > other
        }
    }
}
