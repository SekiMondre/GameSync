

public protocol CodableSaver {
    func save<T>(_ object: T) async throws where T: Codable
}

enum GameSyncError: Error {
    case localPlayerNotAuthenticated
    case dataAlreadyOwnedByPlayer(_ id: String)
    case cannotSyncDifferentPlayersData
}

public actor DefaultGameCenterDataStore<L>: GameCenterDataStore where L: GKEntry & Equatable & Xurimba {
    
    public typealias T = L
    
    public var saver: CodableSaver
    
    public var gameCenter: GameCenter
    
    public var currentPlayerID: String?
    
    public var leaderboardEntries: [String: L] = [:]
    
    public var achievements: [String: Achievement] = [:]
    
    public var isDirty = false

    public init(saver: CodableSaver, gameCenter: GameCenter = GameCenterWrapper()) {
        self.gameCenter = gameCenter
        self.saver = saver
    }
}

public protocol Xurimba {
    init(leaderboardID: String, gkEntry: GKEntry)
}

public protocol GameCenterDataStore: Actor {
    associatedtype T: GKEntry, Equatable, Xurimba
    var saver: CodableSaver { get }
    var gameCenter: GameCenter { get }
    var currentPlayerID: String? { get set }
//    var leaderboardEntries: [String: LeaderboardEntry] { get set }
    var leaderboardEntries: [String: T] { get set }
    var achievements: [String: Achievement] { get set }
    var isDirty: Bool { get set }
}

private extension GameCenterDataStore {
    
    func setPlayerID(_ playerID: String) {
        currentPlayerID = playerID
        isDirty = true
    }
}

private struct GCData: Codable {
    let playerID: String?
    let leaderboards: [String: LeaderboardEntry]
    let achievements: [String: Achievement]
}

public extension GameCenterDataStore {
    
    func saveIfNeeded() async throws {
        if isDirty {
//            let gc = GCData(playerID: currentPlayerID, leaderboards: leaderboardEntries, achievements: achievements)
//            try await saver.save(gc)
            isDirty = false
        }
    }
    
    func handleAuthentication() async throws {
        let authID = try gameCenter.authenticatedPlayerID
        guard let currentPlayerID else {
            setPlayerID(authID)
            try await saveIfNeeded()
            return
        }
        if authID != currentPlayerID { // player identity changed, overwrite saved data
            leaderboardEntries.removeAll()
            achievements.removeAll()
            setPlayerID(authID)
            try await saveIfNeeded()
        }
    }
    
//    func setLeaderboardEntry(_ entry: LeaderboardEntry) {
//        if entry != leaderboardEntries[entry.leaderboardID] {
//            leaderboardEntries[entry.leaderboardID] = entry
//            isDirty = true
//        }
//    }
    func setLeaderboardEntry(_ entry: T, forID leaderboardID: String) {
        if entry != leaderboardEntries[leaderboardID] {
            leaderboardEntries[leaderboardID] = entry
            isDirty = true
        }
    }
    
    func setAchievement(_ achievement: Achievement) {
        if achievement != achievements[achievement.identifier] {
            achievements[achievement.identifier] = achievement
            isDirty = true
        }
    }
    
    func evaluateLeaderboardEntry(_ entry: T, forID leaderboardID: String) async throws {
        if entry.score > leaderboardEntries[leaderboardID]?.score ?? 0 {
            setLeaderboardEntry(entry, forID: leaderboardID)
            try await saveIfNeeded()
        }
        if let leaderboard = try await gameCenter.loadLeaderboards(IDs: [leaderboardID]).first {
            let remote = try await gameCenter.loadEntry(for: leaderboard)
            if entry.score > remote?.score ?? 0 {
                try await gameCenter.submitScore(entry.score, for: leaderboard)
            }
        }
    }
    
//    func evaluateLeaderboardEntry(_ entry: LeaderboardEntry) async throws {
//        if entry.score > leaderboardEntries[entry.leaderboardID]?.score ?? 0 {
//            setLeaderboardEntry(entry)
//            try await saveIfNeeded()
//        }
//        if let leaderboard = try await gameCenter.loadLeaderboards(IDs: [entry.leaderboardID]).first {
//            let remote = try await gameCenter.loadEntry(for: leaderboard)
//            if entry.score > remote?.score ?? 0 {
//                try await gameCenter.submitScore(entry.score, for: leaderboard)
//            }
//        }
//    }
    
    func evaluateAchievement(_ achievement: Achievement) async throws {
        if achievement.percentComplete > achievements[achievement.identifier]?.percentComplete ?? 0.0 {
            setAchievement(achievement)
            try await saveIfNeeded()
        }
        let remote = try await gameCenter.loadAchievements().first { $0.identifier == achievement.identifier }
        if achievement.percentComplete > remote?.percentComplete ?? 0.0 {
            try await gameCenter.reportAchievements([achievement])
        }
    }
    
    func syncAllData() async throws {
        try await handleAuthentication()
        try await syncLeaderboardsWithGameCenter(IDs: [])
        try await syncAchievementsWithGameCenter(IDs: [])
        try await saveIfNeeded()
    }
    
    // TODO: Use task group to submit scores in parallel
    func syncLeaderboardsWithGameCenter(IDs: [String]) async throws {
        guard try gameCenter.authenticatedPlayerID == currentPlayerID else {
            throw GameSyncError.cannotSyncDifferentPlayersData
        }
        
        let leaderboards = try await gameCenter.loadLeaderboards(IDs: IDs)
        let remoteEntries = try await gameCenter.loadEntries(for: leaderboards)
//        let a = leaderboardEntries[id]
        for leaderboard in leaderboards {
            let id = leaderboard.baseLeaderboardID
            try await DiffNullables(leaderboardEntries[id], remoteEntries[id]).diff { local, remote in
                if local ~> remote {
                    try await gameCenter.submitScore(local.score, for: leaderboard)
                } else if local <~ remote {
                    setLeaderboardEntry(T(leaderboardID: id, gkEntry: remote), forID: id)
                }
            } onlyA: { local in
                try await gameCenter.submitScore(local.score, for: leaderboard)
            } onlyB: { remote in
                setLeaderboardEntry(T(leaderboardID: id, gkEntry: remote), forID: id)
            }
        }
    }
    
    func syncAchievementsWithGameCenter(IDs: [String]) async throws {
        guard try gameCenter.authenticatedPlayerID == currentPlayerID else {
            throw GameSyncError.cannotSyncDifferentPlayersData
        }
        
        let remoteAchievements = Dictionary(grouping: try await gameCenter.loadAchievements()) { $0.identifier }
            .mapValues { $0[0] }
        
        var toSend = [Achievement]()
        for id in IDs {
            await DiffNullables(achievements[id], remoteAchievements[id]).diff { local, remote in
                if local ~> remote {
                    toSend.append(local)
                } else if local <~ remote {
                    setAchievement(Achievement(gkAchievement: remote))
                }
            } onlyA: { local in
                toSend.append(local)
            } onlyB: { remote in
                setAchievement(Achievement(gkAchievement: remote))
            }
        }
        try await gameCenter.reportAchievements(toSend) // submit all in just a single call
    }
}
