//public actor GameCenterSynchronizer {
//    
//    var leaderboardIDs: [String] = []
//    var achievementIDs: [String] = []
//    
//    public init() {}
//    
//    public func setLeaderboardIDs(_ leaderboardIDs: [String]) {
//        self.leaderboardIDs = leaderboardIDs
//    }
//    
//    public func synchronize(_ storage: GameCenterDataStore, to gameCenter: GameCenter = GameCenterWrapper()) async throws {
//        if gameCenter.isAuthenticated {
//            try await syncGameCenterData(storage, gameCenter)
//        }
//    }
//    
//    private func syncGameCenterData(_ storage: GameCenterDataStore, _ gameCenter: GameCenter) async throws {
//        
////        if let currentPlayerID = await storage.currentPlayerID {
////            if currentPlayerID != gameCenter.localPlayerID {
////                try await storage.overwriteSave()
////            }
////        } else {
////            try await storage.bindPlayerID(gameCenter.localPlayerID)
////        }
//        
//        try await storage.handleAuthentication()
//        
//        try await syncLeaderboards(storage, gameCenter)
//        try await syncAchievements(storage, gameCenter)
//        
//        try await storage.saveIfNeeded()
//    }
//    
//    // TODO: Use task group to submit scores in parallel
//    private func syncLeaderboards(_ storage: GameCenterDataStore, _ gameCenter: GameCenter) async throws {
//        let leaderboards = try await gameCenter.loadLeaderboards(IDs: leaderboardIDs)
//        let remoteEntries = try await gameCenter.loadEntries(for: leaderboards)
//        
//        let locals = await storage.leaderboardEntries
//        
//        for leaderboard in leaderboards {
//            let id = leaderboard.baseLeaderboardID
//            try await DiffNullables(locals[id], remoteEntries[id]).diff { local, remote in
//                if local ~> remote {
//                    try await gameCenter.submitScore(local.score, for: leaderboard)
//                } else if local <~ remote {
//                    await storage.setLeaderboardEntry(LeaderboardEntry(leaderboardID: id, gkEntry: remote))
//                }
//            } onlyA: { local in
//                try await gameCenter.submitScore(local.score, for: leaderboard)
//            } onlyB: { remote in
//                await storage.setLeaderboardEntry(LeaderboardEntry(leaderboardID: id, gkEntry: remote))
//            }
//        }
//    }
//    
//    private func syncAchievements(_ storage: GameCenterDataStore, _ gameCenter: GameCenter) async throws {
//        let remoteList = try await gameCenter.loadAchievements()
//        let remotes = Dictionary(grouping: remoteList) { $0.identifier }.mapValues { $0[0] }
//        
//        let locals = await storage.achievements
//        
//        var toSend = [Achievement]()
//        for id in achievementIDs {
//            let local = locals[id]
//            let remote = remotes[id]
//            
//            await DiffNullables(local, remote).diff { local, remote in
//                if local ~> remote {
//                    toSend.append(local)
//                } else if local <~ remote {
//                    await storage.setAchievement(Achievement(gkAchievement: remote))
//                }
//            } onlyA: { local in
//                toSend.append(local)
//            } onlyB: { remote in
//                await storage.setAchievement(Achievement(gkAchievement: remote))
//            }
//        }
//        try await gameCenter.reportAchievements(toSend) // submit all in just a single call
//    }
//}
//
