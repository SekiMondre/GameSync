 import GameKit

public protocol GKEntry {
    var context: Int { get }
    var date: Date { get }
    var formattedScore: String { get }
    var rank: Int { get }
    var score: Int { get }
    var gamePlayerID: String { get }
}

extension GKLeaderboard.Entry: GKEntry {
    public var gamePlayerID: String { player.gamePlayerID }
}

public protocol GameCenter {
    var isAuthenticated: Bool { get }
    var localPlayerID: String { get }
    func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard]
    func loadHighscores(for leaderboards: [GKLeaderboard]) async throws -> [String: GKEntry]
    func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws
}

public class GameCenterWrapper: GameCenter {
    
    public init() {}
    
    public var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }
    
    public var localPlayerID: String {
        GKLocalPlayer.local.gamePlayerID
    }
    
    public func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard] {
        try await GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs)
    }
    
    public func loadHighscores(for leaderboards: [GKLeaderboard]) async throws -> [String: GKEntry] {
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
    
    public func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws {
        try await gkLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local)
    }
}
