import Foundation

extension SortOrder {
    static var highToLow: SortOrder { .forward }
    static var lowToHigh: SortOrder { .reverse }
}

public protocol LeaderboardEntry {
    var score: Int { get }
    var sortOrder: SortOrder { get }
}

extension LeaderboardEntry {
    public func ranksHigherThan(_ other: LeaderboardEntry) -> Bool {
        switch sortOrder {
        case .forward:
            return score > other.score
        case .reverse:
            return score < other.score
        }
    }
}

public protocol GameCenterLeaderboardEntry: LeaderboardEntry, Equatable, Codable {
    var gamePlayerID: String { get }
    init(leaderboardID: String, gkEntry: GKEntry) async throws
}

extension GameCenterLeaderboardEntry {
    
    public var contextFlags: Int {
        switch sortOrder {
        case .forward:
            return 0
        case .reverse:
            return 1 << 0 // TODO: Use option flags to allow flexible use cases
        }
    }
}
