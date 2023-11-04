private struct GameCenterData<Leaderboard: Codable, Achievement: Codable>: Codable {
    let playerID: String?
    let leaderboards: [String: Leaderboard]
    let achievements: [String: Achievement]
}

public protocol SaveDelegate: AnyObject {
    func save<T>(_ object: T) async throws where T: Encodable
    func load<T>() async throws -> T? where T: Decodable
}

public protocol GameCenterDataStore: Actor {
    associatedtype LeaderboardType: GameCenterLeaderboardEntry
    associatedtype AchievementType: GameCenterAchievement
    var saver: SaveDelegate? { get set }
    var gameCenter: GameCenter { get }
    var currentPlayerID: String? { get set }
    var leaderboardEntries: [String: LeaderboardType] { get set }
    var achievements: [String: AchievementType] { get set }
    var isDirty: Bool { get set }
}

private extension GameCenterDataStore {
    
    func setPlayerID(_ playerID: String) {
        currentPlayerID = playerID
        isDirty = true
    }
}

public extension GameCenterDataStore {
    
    func setSaveDelegate(_ delegate: SaveDelegate) {
        self.saver = delegate
    }
    
    func loadLocalData() async throws {
        guard let saver else {
            throw GameSyncError.saveDelegateNotSet
        }
        guard let gc: GameCenterData<LeaderboardType, AchievementType> = try await saver.load() else {
            throw GameSyncError.saveFileNotFound
        }
        self.currentPlayerID = gc.playerID
        self.leaderboardEntries = gc.leaderboards
        self.achievements = gc.achievements
    }
    
    func saveLocalData() async throws {
        guard let saver else {
            throw GameSyncError.saveDelegateNotSet
        }
        let gc = GameCenterData<LeaderboardType, AchievementType>(
            playerID: currentPlayerID,
            leaderboards: leaderboardEntries,
            achievements: achievements)
        try await saver.save(gc)
        isDirty = false
    }
    
    func saveIfNeeded() async throws {
        if isDirty {
            try await saveLocalData()
        }
    }
    
    func handleAuthentication(triggerSave: Bool = true) async throws {
        let authID = try gameCenter.authenticatedPlayerID
        guard let currentPlayerID else {
            setPlayerID(authID)
            if triggerSave {
                try await saveLocalData()
            }
            return
        }
        if authID != currentPlayerID { // player identity changed, overwrite saved data
            leaderboardEntries.removeAll()
            achievements.removeAll()
            setPlayerID(authID)
            if triggerSave {
                try await saveLocalData()
            }
        }
    }
    
    func setLeaderboardEntry(_ entry: LeaderboardType, forID leaderboardID: String) {
        if entry != leaderboardEntries[leaderboardID] {
            leaderboardEntries[leaderboardID] = entry
            isDirty = true
        }
    }
    
    func setAchievement(_ achievement: AchievementType) {
        if achievement != achievements[achievement.identifier] {
            achievements[achievement.identifier] = achievement
            isDirty = true
        }
    }
    
    func evaluateLeaderboardEntry(_ entry: LeaderboardType, forID leaderboardID: String) async throws {
        let local = leaderboardEntries[leaderboardID]
        if local == nil || entry.ranksHigherThan(local!) {
            setLeaderboardEntry(entry, forID: leaderboardID)
            try await saveIfNeeded()
        }
        if let leaderboard = try await gameCenter.loadLeaderboards(IDs: [leaderboardID]).first {
            let remote = try await gameCenter.loadEntry(for: leaderboard)
            if remote == nil || entry.ranksHigherThan(remote!) {
                try await gameCenter.submitScore(entry.score, context: entry.contextFlags, for: leaderboard)
            }
        }
    }
    
    func evaluateAchievement(_ achievement: AchievementType) async throws {
        if achievement.percentComplete > achievements[achievement.identifier]?.percentComplete ?? 0.0 {
            setAchievement(achievement)
            try await saveIfNeeded()
        }
        let remote = try await gameCenter.loadAchievements().first { $0.identifier == achievement.identifier }
        if achievement.percentComplete > remote?.percentComplete ?? 0.0 {
            try await gameCenter.reportAchievements([achievement.gkAchievement()])
        }
    }
    
    func syncAllData(leaderboardIDs: [String], achievementIDs: [String]) async throws {
        try await handleAuthentication(triggerSave: false)
        try await syncLeaderboardsWithGameCenter(IDs: leaderboardIDs)
        try await syncAchievementsWithGameCenter(IDs: achievementIDs)
        try await saveIfNeeded()
    }
    
    // TODO: Use task group to submit scores in parallel
    func syncLeaderboardsWithGameCenter(IDs: [String]) async throws {
        guard try gameCenter.authenticatedPlayerID == currentPlayerID else {
            throw GameSyncError.cannotSyncDifferentPlayersData
        }
        
        let leaderboards = try await gameCenter.loadLeaderboards(IDs: IDs)
        let remoteEntries = try await gameCenter.loadEntries(for: leaderboards)
        
        for leaderboard in leaderboards {
            let id = leaderboard.baseLeaderboardID
            try await DiffNullables(leaderboardEntries[id], remoteEntries[id]).diff { local, remote in
                if local ~> remote {
                    try await gameCenter.submitScore(local.score, context: local.contextFlags, for: leaderboard)
                } else if local <~ remote {
                    setLeaderboardEntry(try await LeaderboardType(leaderboardID: id, gkEntry: remote), forID: id)
                }
            } onlyA: { local in
                try await gameCenter.submitScore(local.score, context: local.contextFlags, for: leaderboard)
            } onlyB: { remote in
                setLeaderboardEntry(try await LeaderboardType(leaderboardID: id, gkEntry: remote), forID: id)
            }
        }
    }
    
    func syncAchievementsWithGameCenter(IDs: [String]) async throws {
        guard try gameCenter.authenticatedPlayerID == currentPlayerID else {
            throw GameSyncError.cannotSyncDifferentPlayersData
        }
        
        let remoteAchievements = Dictionary(grouping: try await gameCenter.loadAchievements()) { $0.identifier }
            .mapValues { $0[0] }
        
        var toSend = [AchievementType]()
        for id in IDs {
            await DiffNullables(achievements[id], remoteAchievements[id]).diff { local, remote in
                if local ~> remote {
                    toSend.append(local)
                } else if local <~ remote {
                    setAchievement(AchievementType(gkAchievement: remote))
                }
            } onlyA: { local in
                toSend.append(local)
            } onlyB: { remote in
                setAchievement(AchievementType(gkAchievement: remote))
            }
        }
        try await gameCenter.reportAchievements(toSend.map{ $0.gkAchievement() }) // submit all in just a single call
    }
}
