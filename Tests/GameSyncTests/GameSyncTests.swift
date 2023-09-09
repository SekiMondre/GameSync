import XCTest
@testable import GameSync

final class GameSyncTests: XCTestCase {
    
    var synchronizer: GameCenterSynchronizer!
    
    var gameCenter: GameCenterMock!
    var localStorage: GameCenterStorageMock!
    
    let testID = "test.leaderboard"
    
    override func setUp() async throws {
        self.gameCenter = GameCenterMock()
        self.localStorage = GameCenterStorageMock()
        
        gameCenter.localPlayerID = "A:_71954f10ba907b1d80955302260d67b4"
        gameCenter.isAuthenticated = true
        
        synchronizer = GameCenterSynchronizer()
        await synchronizer.setLeaderboardIDs([testID])
    }
    
    func testSyncSubmitLocal() async throws {
        let entry = GKEntryStub.make(score: 69)
        try await localStorage.setEntry(entry, forID: testID)
        
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        XCTAssertEqual(gameCenter.submittedScores[testID], entry.score, "A local-only score entry must be submitted.")
    }
    
    func testSyncSaveRemote() async throws {
        let entry = GKEntryStub.make(score: 420)
        gameCenter.entriesToReturn[testID] = entry
        
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        let highscore = try await localStorage.getScore(for: testID)
        XCTAssertEqual(highscore, entry.score, "A remote-only score entry must be saved.")
    }
    
    func testSyncConflictLocal() async throws {
        let localEntry = GKEntryStub.make(score: 420)
        let remoteEntry = GKEntryStub.make(score: 69)
        try await localStorage.setEntry(localEntry, forID: testID)
        gameCenter.entriesToReturn[testID] = remoteEntry
        
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        let highscore = try await localStorage.getScore(for: testID)
        XCTAssertEqual(highscore, localEntry.score)
        XCTAssertEqual(gameCenter.submittedScores[testID], localEntry.score, "A local record must be submitted.")
    }
    
    func testSyncConflictRemote() async throws {
        let localEntry = GKEntryStub.make(score: 69)
        let remoteEntry = GKEntryStub.make(score: 420)
        try await localStorage.setEntry(localEntry, forID: testID)
        gameCenter.entriesToReturn[testID] = remoteEntry
        
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        let highscore = try await localStorage.getScore(for: testID)
        XCTAssertEqual(highscore, remoteEntry.score)
        XCTAssertNil(gameCenter.submittedScores[testID], "A remote record must be saved.")
    }
    
    func testFirstAuthBindsPlayerID() async throws {
        let currentID = await localStorage.currentPlayerID
        XCTAssertNil(currentID)
        
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        let hasOverwritten = await localStorage.hasOverwrittenSave
        XCTAssertFalse(hasOverwritten, "First time auth does not overwrite unowned saved data.")
        let afterAuthID = await localStorage.currentPlayerID
        XCTAssertEqual(afterAuthID, gameCenter.localPlayerID, "First time auth binds local data to player ID.")
    }
    
    func testAnotherPlayerAuthReplacesID() async throws {
        let localEntry = GKEntryStub.make(score: 420)
        let remoteEntry = GKEntryStub.make(score: 69)
        try await localStorage.setEntry(localEntry, forID: testID)
        gameCenter.entriesToReturn[testID] = remoteEntry
        
        await localStorage.bindPlayerID("0xd3adb3ef")
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        
        let highscore = try await localStorage.getScore(for: testID)
        XCTAssertEqual(highscore, remoteEntry.score, "Changing accounts replaces the previous local score.")
        let hasOverwritten = await localStorage.hasOverwrittenSave
        XCTAssertTrue(hasOverwritten, "Changing accounts overwrites saved data.")
        let afterAuthID = await localStorage.currentPlayerID
        XCTAssertEqual(afterAuthID, gameCenter.localPlayerID)
    }
    
    func testTryToSaveOnAuth() async throws {
        try await synchronizer.synchronize(localStorage, to: gameCenter)
        let saveFlag = await localStorage.hasTriedSaving
        XCTAssertTrue(saveFlag, "After syncing, game must try to be saved.")
    }
}
