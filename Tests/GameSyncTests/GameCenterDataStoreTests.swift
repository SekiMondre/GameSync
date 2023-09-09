import XCTest
import GameKit
@testable import GameSync

let testIDs = ["test.leaderboard"]
fileprivate var testID = testIDs[0]

final class SaverSpy: CodableSaver {
    
    var didCallSave = false
    
    func save<T>(_ object: T) async throws where T : Decodable, T : Encodable {
        self.didCallSave = true
    }
}

final class GameCenterDataStoreTesWts: XCTestCase {
    
//    var dataStore: GameCenterDataStore!
    var dataStore: DefaultGameCenterDataStore<LeaderboardEntry>!
    
    var gameCenter: GameCenterMock!
    var saverSpy: SaverSpy!
    
    override func setUp() async throws {
        self.gameCenter = GameCenterMock()
        self.saverSpy = SaverSpy()
        self.dataStore = DefaultGameCenterDataStore(saver: saverSpy, gameCenter: gameCenter)
        
        gameCenter.localPlayerID = "A:_71954f10ba907b1d80955302260d67b4"
        gameCenter.isAuthenticated = true
    }
    
    func testFirstAuthSetsPlayerID() async throws {
        let currentID = await dataStore.currentPlayerID
        XCTAssertNil(currentID)
        
        try await dataStore.handleAuthentication()
        
        let afterAuthID = await dataStore.currentPlayerID
        XCTAssertEqual(afterAuthID, gameCenter.localPlayerID, "First time auth binds local data to player ID.")
        XCTAssertTrue(saverSpy.didCallSave)
    }
    
    func testAnotherAuthOverwritesSave() async throws {
        try await dataStore.handleAuthentication()
        let firstID = await dataStore.currentPlayerID
        
        gameCenter.localPlayerID = "0xd3adb3ef"
        try await dataStore.handleAuthentication()
        
        let afterAuthID = await dataStore.currentPlayerID
        XCTAssertNotEqual(afterAuthID, firstID, "Different player auth overwrites local data.")
        XCTAssertTrue(saverSpy.didCallSave)
    }
    
    // TODO: evaluate tests
    
    // Sync tests
    
    func testSyncLeaderboardsSubmitLocal() async throws {
        let entry = LeaderboardEntry.make(score: 69)
        await dataStore.setLeaderboardEntry(entry)
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncLeaderboardsWithGameCenter(IDs: testIDs)

        XCTAssertEqual(gameCenter.submittedEntries[testID], entry.score, "A local-only score entry must be submitted.")
    }
    
    func testSyncLeaderboardsSaveRemote() async throws {
        let entry = GKEntryStub.make(score: 420)
        gameCenter.entriesToReturn[testID] = entry
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncLeaderboardsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.leaderboardEntries[testID]
        XCTAssertEqual(current?.score, entry.score, "A remote-only score entry must be saved.")
    }
    
    func testSyncLeaderboardsConflictResolveToLocal() async throws {
        let local = LeaderboardEntry.make(score: 420)
        await dataStore.setLeaderboardEntry(local)
        let remote = GKEntryStub.make(score: 69)
        gameCenter.entriesToReturn[testID] = remote
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncLeaderboardsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.leaderboardEntries[testID]
        XCTAssertEqual(current?.score, local.score)
        XCTAssertEqual(gameCenter.submittedEntries[testID], local.score, "A local record must be submitted.")
    }
    
    func testSyncLeaderboardsConflictResolveToRemote() async throws {
        let local = LeaderboardEntry.make(score: 69)
        await dataStore.setLeaderboardEntry(local)
        let remote = GKEntryStub.make(score: 420)
        gameCenter.entriesToReturn[testID] = remote
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncLeaderboardsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.leaderboardEntries[testID]
        XCTAssertEqual(current?.score, remote.score)
        XCTAssertNil(gameCenter.submittedEntries[testID], "A remote record must be saved.")
    }
    
    // MARK: Achievements
    
    func testSyncAchievementsSubmitLocal() async throws {
        let local = Achievement(identifier: testID)
        await dataStore.setAchievement(local)
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncAchievementsWithGameCenter(IDs: testIDs)
        
        XCTAssertEqual(gameCenter.submittedAchievements[testID]?.percentComplete, local.percentComplete)
    }
    
    func testSyncAchievementsSaveRemote() async throws {
        let remote = GKAchievement(identifier: testID)
        remote.percentComplete = 100.0
        gameCenter.achievementsToReturn = [remote]
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncAchievementsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.achievements[testID]
        XCTAssertEqual(current?.percentComplete, remote.percentComplete)
    }
    
    func testSyncAchievementsConflictResolveToLocal() async throws {
        let local = Achievement(identifier: testID, percentComplete: 69)
        await dataStore.setAchievement(local)
        let remote = GKAchievement(identifier: testID)
        remote.percentComplete = 42
        gameCenter.achievementsToReturn = [remote]
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncAchievementsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.achievements[testID]
        XCTAssertEqual(current?.percentComplete, local.percentComplete)
        XCTAssertEqual(gameCenter.submittedAchievements[testID]?.percentComplete, local.percentComplete)
    }
    
    func testSyncAchievementsConflictResolveToRemote() async throws {
        let local = Achievement(identifier: testID, percentComplete: 42)
        await dataStore.setAchievement(local)
        let remote = GKAchievement(identifier: testID)
        remote.percentComplete = 69
        gameCenter.achievementsToReturn = [remote]
        
        try await dataStore.handleAuthentication()
        try await dataStore.syncAchievementsWithGameCenter(IDs: testIDs)
        
        let current = await dataStore.achievements[testID]
        XCTAssertEqual(current?.percentComplete, remote.percentComplete)
        XCTAssertNil(gameCenter.submittedAchievements[testID])
    }
}
