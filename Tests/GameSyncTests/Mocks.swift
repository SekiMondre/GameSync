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
    
    private(set) var submittedScores: [String: Int] = [:]
    
    var entriesToReturn: [String: GKEntry] = [:]

    var isAuthenticated: Bool = false

    var localPlayerID: String = ""
    
    func loadLeaderboards(IDs leaderboardIDs: [String]) async throws -> [GKLeaderboard] {
        leaderboardIDs.map { GKLeaderboardMock(id: $0) }
    }
    
    func loadHighscores(for leaderboards: [GKLeaderboard]) async throws -> [String : GKEntry] {
        var entries = [String: GKEntry]()
        for leaderboard in leaderboards {
            entries[leaderboard.baseLeaderboardID] = entriesToReturn[leaderboard.baseLeaderboardID]
        }
        return entries
    }
    
    func submitScore(_ score: Int, for gkLeaderboard: GKLeaderboard) async throws {
        submittedScores[gkLeaderboard.baseLeaderboardID] = score
    }
}

struct GKEntryStub: GKEntry {
    var context: Int = 0
    var date: Date = Date()
    var formattedScore: String = ""
    var rank: Int = 0
    var score: Int = 0
    var gamePlayerID: String = ""
    
    static func make(score: Int) -> GKEntry {
        var stub = GKEntryStub()
        stub.score = score
        return stub
    }
}

actor GameCenterStorageMock: GameCenterDataStore {
    
    var currentPlayerID: String?
    
    var hasTriedSaving = false
    var hasOverwrittenSave = false
    
    private(set) var cache: [String: Int] = [:]
    
    func bindPlayerID(_ playerID: String) {
        self.currentPlayerID = playerID
    }
    
    func getScore(for leaderboardID: String) async throws -> Int? {
        cache[leaderboardID]
    }
    
    func setEntry(_ entry: GameSync.GKEntry, forID leaderboardID: String) async throws {
        cache[leaderboardID] = entry.score
    }
    
    func overwriteSave(newPlayerID: String) async throws {
        cache.removeAll()
        currentPlayerID = newPlayerID
        hasOverwrittenSave = true
    }
    
    func saveIfNeeded() async throws {
        hasTriedSaving = true
    }
    
    func save<T>(_ object: T) async throws where T : Decodable, T : Encodable {
        
    }
}
