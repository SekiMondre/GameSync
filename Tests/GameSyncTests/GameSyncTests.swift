import XCTest
@testable import GameSync

fileprivate let testID = "test.leaderboard"

extension LeaderboardEntry {
    static func make(score: Int, id: String = testID) -> LeaderboardEntry {
        LeaderboardEntry(leaderboardID: id, gkEntry: GKEntryStub.make(score: score))
    }
}

//final class GameSyncTests: XCTestCase {
//
//    var synchronizer: GameCenterSynchronizer!
//
//    var gameCenter: GameCenterMock!
//    var localStorage: GameCenterStorageMock!
//
//    override func setUp() async throws {
//        self.gameCenter = GameCenterMock()
//        self.localStorage = GameCenterStorageMock(gameCenter: gameCenter)
//
//        gameCenter.localPlayerID = "A:_71954f10ba907b1d80955302260d67b4"
//        gameCenter.isAuthenticated = true
//
//        synchronizer = GameCenterSynchronizer()
//        await synchronizer.setLeaderboardIDs([testID])
//    }
//
//    func testSyncSubmitLocal() async throws {
//        let entry = LeaderboardEntry.make(score: 69)
//        await localStorage.setLeaderboardEntry(entry)//(entry, forID: testID)
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
//        XCTAssertEqual(gameCenter.submittedScores[testID], entry.score, "A local-only score entry must be submitted.")
//    }
//
//    func testSyncSaveRemote() async throws {
//        let entry = GKEntryStub.make(score: 420)
//        gameCenter.entriesToReturn[testID] = entry
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
//        let localEntry = await localStorage.leaderboardEntries[testID]
//        XCTAssertEqual(localEntry?.score, entry.score, "A remote-only score entry must be saved.")
//    }
//
//    func testSyncConflictLocal() async throws {
//        let localEntry = LeaderboardEntry.make(score: 420)
//        let remoteEntry = GKEntryStub.make(score: 69)
//        await localStorage.setLeaderboardEntry(localEntry)
//        gameCenter.entriesToReturn[testID] = remoteEntry
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
//        let newEntry = await localStorage.leaderboardEntries[testID]
//        XCTAssertEqual(newEntry?.score, localEntry.score)
//        XCTAssertEqual(gameCenter.submittedScores[testID], localEntry.score, "A local record must be submitted.")
//    }
//
//    func testSyncConflictRemote() async throws {
//        let localEntry = LeaderboardEntry.make(score: 69)
//        let remoteEntry = GKEntryStub.make(score: 420)
//        await localStorage.setLeaderboardEntry(localEntry)
////        try await localStorage.setEntry(localEntry, forID: testID)
//        gameCenter.entriesToReturn[testID] = remoteEntry
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
//        let newEntry = await localStorage.leaderboardEntries[testID]
//        XCTAssertEqual(newEntry?.score, remoteEntry.score)
//        XCTAssertNil(gameCenter.submittedScores[testID], "A remote record must be saved.")
//    }
//
//    func testFirstAuthBindsPlayerID() async throws {
//        let currentID = await localStorage.currentPlayerID
//        XCTAssertNil(currentID)
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
////        let hasOverwritten = await localStorage.hasOverwrittenSave
////        XCTAssertFalse(hasOverwritten, "First time auth does not overwrite unowned saved data.")
//        let afterAuthID = await localStorage.currentPlayerID
//        XCTAssertEqual(afterAuthID, gameCenter.localPlayerID, "First time auth binds local data to player ID.")
//    }
//
//    func testAnotherPlayerAuthReplacesID() async throws {
////        let localEntry = GKEntryStub.make(score: 420)
//        let localEntry = LeaderboardEntry.make(score: 420)
//        let remoteEntry = GKEntryStub.make(score: 69)
//        await localStorage.setLeaderboardEntry(localEntry)
//        try await localStorage.handleAuthentication()
//
//        gameCenter.localPlayerID = "0xd3adb3ef"
//        gameCenter.entriesToReturn[testID] = remoteEntry
//
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//
//        let newEntry = await localStorage.leaderboardEntries[testID]
//        XCTAssertEqual(newEntry?.score, remoteEntry.score, "Changing accounts replaces the previous local score.")
////        let hasOverwritten = await localStorage.hasOverwrittenSave
////        XCTAssertTrue(hasOverwritten, "Changing accounts overwrites saved data.")
//        let afterAuthID = await localStorage.currentPlayerID
//        XCTAssertEqual(afterAuthID, gameCenter.localPlayerID)
//    }
//
//    func testTryToSaveOnAuth() async throws {
//        try await synchronizer.synchronize(localStorage, to: gameCenter)
//        let saveFlag = await localStorage.hasTriedSaving
//        XCTAssertTrue(saveFlag, "After syncing, game must try to be saved.")
//    }
//}
