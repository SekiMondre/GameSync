public actor GameCenterSynchronizer {
    
    var leaderboardIDs: [String] = []
    
    public init() {}
    
    public func setLeaderboardIDs(_ leaderboardIDs: [String]) {
        self.leaderboardIDs = leaderboardIDs
    }
    
    public func synchronize(_ storage: GameCenterDataStore, to gameCenter: GameCenter = GameCenterWrapper()) async throws {
        if gameCenter.isAuthenticated {
            try await syncGameCenterData(storage, gameCenter)
        }
    }
    
    private func syncGameCenterData(_ storage: GameCenterDataStore, _ gameCenter: GameCenter) async throws {
        
        if let currentPlayerID = await storage.currentPlayerID {
            if currentPlayerID != gameCenter.localPlayerID {
                try await storage.overwriteSave(newPlayerID: gameCenter.localPlayerID)
            }
        } else {
            await storage.bindPlayerID(gameCenter.localPlayerID)
        }
        
        let leaderboards = try await gameCenter.loadLeaderboards(IDs: leaderboardIDs)
        let gkEntries = try await gameCenter.loadHighscores(for: leaderboards)
        
        for leaderboard in leaderboards {
            let leaderboardID = leaderboard.baseLeaderboardID
            
            if let remoteScore = gkEntries[leaderboardID] {
                if let localScore = try await storage.getScore(for: leaderboardID) {
                    if remoteScore.score >= localScore {
                        try await storage.setEntry(remoteScore, forID: leaderboardID)
                    } else {
                        try await gameCenter.submitScore(localScore, for: leaderboard)
                    }
                } else {
                    try await storage.setEntry(remoteScore, forID: leaderboardID)
                }
            } else if let localScore = try await storage.getScore(for: leaderboardID) {
                try await gameCenter.submitScore(localScore, for: leaderboard)
            }
        }
        try await storage.saveIfNeeded()
    }
}
