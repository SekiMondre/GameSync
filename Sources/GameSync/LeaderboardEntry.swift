public struct LeaderboardEntry: GameCenterLeaderboardEntry {
    
    public var leaderboardID: String
    public var score: Int
    public var gamePlayerID: String
    public var isReversed: Bool
    
    public init(leaderboardID: String, gkEntry: GKEntry) async throws {
        self.leaderboardID = leaderboardID
        self.score = gkEntry.score
        self.gamePlayerID = gkEntry.gamePlayerID
        self.isReversed = false
    }
}
