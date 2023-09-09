import GameKit
@testable import GameSync

class GKLeaderboardMock: GKLeaderboard {
    
    override var baseLeaderboardID: String { _id }
    
    private let _id: String
    
    init(id: String) {
        _id = id
        super.init()
    }
}

final class GameCenterMock: GameCenter {
    
    private(set) var submittedEntries: [String: Int] = [:]
    private(set) var submittedAchievements: [String: Achievement] = [:]
    
    var entriesToReturn: [String: GKEntry] = [:]
    var achievementsToReturn: [GKAchievement] = []

    var isAuthenticated: Bool = false

    var localPlayerID: String = "" {
        didSet {
            entriesToReturn.removeAll()
        }
    }
    
    func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard] {
        leaderboardIDs.map { GKLeaderboardMock(id: $0) }
    }
    
    func loadEntry(for leaderboard: GKLeaderboard) async throws -> GameSync.GKEntry? {
        entriesToReturn[leaderboard.baseLeaderboardID]
    }
    
    func loadEntries(for leaderboards: [GKLeaderboard]) async throws -> [String : GKEntry] {
        var entries = [String: GKEntry]()
        for leaderboard in leaderboards {
            entries[leaderboard.baseLeaderboardID] = entriesToReturn[leaderboard.baseLeaderboardID]
        }
        return entries
    }
    
    func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws {
        submittedEntries[gkLeaderboard.baseLeaderboardID] = score
    }
    
    func loadAchievements() async throws -> [GKAchievement] {
        achievementsToReturn
    }
    
    func reportAchievement(_ achievement: GameSync.Achievement) async throws {
        try await reportAchievements([achievement])
    }
    
    func reportAchievements(_ achievements: [GameSync.Achievement]) async throws {
        for achievement in achievements {
            submittedAchievements[achievement.identifier] = achievement
        }
    }
}



struct GKEntryStub: GKEntry {
    var context: Int = 0
    var date: Date = Date()
    var formattedScore: String = ""
    var rank: Int = 0
    var score: Int = 0
    var gamePlayerID: String = ""
    
    static func make(score: Int) -> GKEntryStub {
        var stub = GKEntryStub()
        stub.score = score
        return stub
    }
}


