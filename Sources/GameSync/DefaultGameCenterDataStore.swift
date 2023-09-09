public actor DefaultGameCenterDataStore<L, A>: GameCenterDataStore
where L: GameCenterLeaderboardEntry, A: GameCenterAchievement
{
    public typealias LeaderboardType = L
    public typealias AchievementType = A
    
    public weak var saver: SaveDelegate?
    public var gameCenter: GameCenter
    public var currentPlayerID: String?
    public var leaderboardEntries: [String: L] = [:]
    public var achievements: [String: A] = [:]
    public var isDirty = false

    public init(gameCenter: GameCenter = GameCenterWrapper()) {
        self.gameCenter = gameCenter
    }
}
