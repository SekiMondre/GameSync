public struct LeaderboardEntry: GameCenterLeaderboardEntry {
    
    public var leaderboardID: String
    public var score: Int
    public var gamePlayerID: String
    
    public init(leaderboardID: String, gkEntry: GKEntry) async throws {
        self.leaderboardID = leaderboardID
        self.score = gkEntry.score
        self.gamePlayerID = gkEntry.gamePlayerID
    }
}
