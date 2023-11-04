import GameKit
@testable import GameSync

extension GKEntry {
    static func stub(score: Int, gamePlayerID: String = "") -> GKEntry {
        var stub = GKEntry()
        stub.score = score
        stub.gamePlayerID = gamePlayerID
        return stub
    }
}

final class SaverSpy: SaveDelegate {
    
    var didCallSave = false
    var didCallLoad = false
    
    func save<T>(_ object: T) async throws where T : Encodable {
        self.didCallSave = true
    }
    
    func load<T>() async throws -> T? where T : Decodable {
        self.didCallLoad = true
        return nil
    }
}

final class GKLeaderboardMock: GKLeaderboard {
    
    override var baseLeaderboardID: String { _id }
    
    private let _id: String
    
    init(id: String) {
        _id = id
        super.init()
    }
}

final class GameCenterMock: GameCenter {
    
    private(set) var submittedEntries: [String: Int] = [:]
    private(set) var submittedAchievements: [String: GKAchievement] = [:]
    
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
    
    func submitScore(_ score: Int, context: Int, for gkLeaderboard: GKLeaderboard) async throws {
        submittedEntries[gkLeaderboard.baseLeaderboardID] = score
    }
    
    func loadAchievements() async throws -> [GKAchievement] {
        achievementsToReturn
    }
    
    func reportAchievements(_ achievements: [GKAchievement]) async throws {
        for achievement in achievements {
            submittedAchievements[achievement.identifier] = achievement
        }
    }
}
