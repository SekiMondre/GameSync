public struct LeaderboardEntry: Equatable, Codable {
    public var leaderboardID: String
    public var score: Int
    public var gamePlayerID: String
    
    init(leaderboardID: String, gkEntry: GKEntry) {
        self.leaderboardID = leaderboardID
        self.score = gkEntry.score
        self.gamePlayerID = gkEntry.gamePlayerID
    }
}
extension LeaderboardEntry: IntComparable {
    public var intValue: Int { score }
}
