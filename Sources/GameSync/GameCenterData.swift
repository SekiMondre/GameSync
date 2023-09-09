public final class GameCenterData<Score> where Score: Codable {
    
    public var playerID: String? {
        didSet {
            isDirty = true
        }
    }
    
    public var highscores: [String: Score] = [:] {
        didSet {
            isDirty = true
        }
    }
    
    private(set) var isDirty = false
    
    public func commit(to coder: CodableSaver) async throws {
        if isDirty {
            try await coder.save(self)
            isDirty = false
        }
    }
    
    public init() {}
}

extension GameCenterData: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case highscores, playerID
    }
}
