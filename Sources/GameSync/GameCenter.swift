 import GameKit

public protocol GameCenter {
    
    // Player Authentication
    
    var isAuthenticated: Bool { get }
    
    var localPlayerID: String { get }
    
    var authenticatedPlayerID: String { get throws }
    
    // Leaderboards
    
    func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard]
    
    func loadEntry(for leaderboard: GKLeaderboard) async throws -> GKEntry?
    
    func loadEntries(for leaderboards: [GKLeaderboard]) async throws -> [String: GKEntry]
    
    func submitScore(_ score: Int, context: Int, for gkLeaderboard: GKLeaderboard) async throws
    
    // Achievements
    
    func loadAchievements() async throws -> [GKAchievement]
    func reportAchievements(_ achievements: [GKAchievement]) async throws
}

public extension GameCenter {
    
    var authenticatedPlayerID: String {
        get throws {
            guard isAuthenticated else {
                throw GameSyncError.localPlayerNotAuthenticated
            }
            return localPlayerID
        }
    }
}

extension GKAchievement: DoubleComparable {
    
    public var doubleValue: Double {
        percentComplete
    }
}

public struct GKEntry: LeaderboardEntry {
    
    public var context: Int
    public var date: Date
    public var formattedScore: String
    public var rank: Int
    public var score: Int
    public var gamePlayerID: String
    
    internal init(gkEntry: GKLeaderboard.Entry) {
        self.context = gkEntry.context
        self.date = gkEntry.date
        self.formattedScore = gkEntry.formattedScore
        self.rank = gkEntry.rank
        self.score = gkEntry.score
        self.gamePlayerID = gkEntry.player.gamePlayerID
    }
    
    public init() {
        self.context = 0
        self.date = Date()
        self.formattedScore = ""
        self.rank = 0
        self.score = 0
        self.gamePlayerID = ""
    }
}

extension GKEntry {
    
    public var sortOrder: SortOrder {
        context == 1 ? .reverse : .forward // TODO: Read from parsed OptionSet context
    }
    
    public func ranksHigherThan(_ other: Int) -> Bool {
        switch sortOrder {
        case .forward:
            return score > other
        case .reverse:
            return score < other
        }
    }
}

open class GameCenterWrapper: GameCenter {
    
    public init() {}
    
    open var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }
    
    open var localPlayerID: String {
        GKLocalPlayer.local.gamePlayerID
    }
    
    open func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard] {
        return try await GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs)
    }
    
    open func loadEntry(for leaderboard: GKLeaderboard) async throws -> GKEntry? {
        return try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime).0.map(GKEntry.init)
    }
    
    open func loadEntries(for leaderboards: [GKLeaderboard]) async throws -> [String: GKEntry] {
        return try await withThrowingTaskGroup(
            of: (String, (GKLeaderboard.Entry?, [GKLeaderboard.Entry])).self,
            returning: [String: GKLeaderboard.Entry].self) { group in
                
            for leaderboard in leaderboards {
                group.addTask {
                    let entry = try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                    return (leaderboard.baseLeaderboardID, entry)
                }
            }
            return try await group.reduce(into: [:]) { $0[$1.0] = $1.1.0 }
            }.mapValues(GKEntry.init)
    }
    
    public func submitScore(_ score: Int, context: Int, for gkLeaderboard: GKLeaderboard) async throws {
        try await gkLeaderboard.submitScore(score, context: context, player: GKLocalPlayer.local)
    }
    
    open func loadAchievements() async throws -> [GKAchievement] {
        return try await GKAchievement.loadAchievements()
    }
    
    open func reportAchievements(_ achievements: [GKAchievement]) async throws {
        try await GKAchievement.report(achievements)
    }
}
