public protocol CodableSaver {
    func save<T>(_ object: T) async throws where T: Codable
}

public protocol GameCenterDataStore: Actor, CodableSaver {
    var currentPlayerID: String? { get }
    func bindPlayerID(_ playerID: String)
    func getScore(for leaderboardID: String) async throws -> Int?
    func setEntry(_ entry: GKEntry, forID leaderboardID: String) async throws
    func overwriteSave(newPlayerID: String) async throws
    func saveIfNeeded() async throws
}

public actor BasicGameCenterDataStore: GameCenterDataStore, CodableSaver {
    
    let save: GameCenterData<Int> = GameCenterData()
    
    public var currentPlayerID: String?
    
    public func bindPlayerID(_ playerID: String) {
        
    }
    
    public func getScore(for leaderboardID: String) async throws -> Int? {
        return save.highscores[leaderboardID]
    }
    
    public func setEntry(_ entry: GKEntry, forID leaderboardID: String) async throws {
        save.highscores[leaderboardID] = entry.score
    }
    
    public func save<T>(_ object: T) async throws where T: Codable {
        try await save.commit(to: self)
    }
    
    public func overwriteSave(newPlayerID: String) async throws {
        
    }
    
    public func saveIfNeeded() async throws {
        
    }
}
