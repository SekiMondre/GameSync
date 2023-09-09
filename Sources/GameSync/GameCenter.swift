 import GameKit

public protocol GKEntry: IntComparable {
    var context: Int { get }
    var date: Date { get }
    var formattedScore: String { get }
    var rank: Int { get }
    var score: Int { get }
    var gamePlayerID: String { get }
}
extension GKEntry {
    public var intValue: Int { score }
}

extension GKLeaderboard.Entry: GKEntry {
    public var gamePlayerID: String { player.gamePlayerID }
}

extension GKAchievement: DoubleComparable {
    public var doubleValue: Double {
        percentComplete
    }
}

public protocol GameCenter {
    
    var isAuthenticated: Bool { get }
    var localPlayerID: String { get }
    var authenticatedPlayerID: String { get throws }
    
    func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard]
    func loadEntry(for leaderboard: GKLeaderboard) async throws -> GKEntry?
    func loadEntries(for leaderboards: [GKLeaderboard]) async throws -> [String: GKEntry]
    func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws
    
    func loadAchievements() async throws -> [GKAchievement]
    func reportAchievement(_ achievement: Achievement) async throws // ?
    func reportAchievements(_ achievements: [Achievement]) async throws
}

public extension GameCenter {
    
    var authenticatedPlayerID: String {
        get throws {
            guard isAuthenticated else { throw GameSyncError.localPlayerNotAuthenticated }
            return localPlayerID
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
        try await GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs)
    }
    
    open func loadEntry(for leaderboard: GKLeaderboard) async throws -> GKEntry? {
        try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime).0
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
        }
    }
    
    open func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws {
        try await gkLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local)
    }
    
    open func loadAchievements() async throws -> [GKAchievement] {
        try await GKAchievement.loadAchievements()
    }
    
    open func reportAchievement(_ achievement: Achievement) async throws {
        try await GKAchievement.report([achievement.gkAchievement])
    }
    
    open func reportAchievements(_ achievements: [Achievement]) async throws {
        try await GKAchievement.report(achievements.map { $0.gkAchievement })
    }
}
