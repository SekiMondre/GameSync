public protocol GameCenterLeaderboardEntry: IntComparable, Equatable, Codable {
    var score: Int { get }
    var gamePlayerID: String { get }
    init(leaderboardID: String, gkEntry: GKEntry) async throws
}

extension GameCenterLeaderboardEntry {
    public var intValue: Int { score }
}
