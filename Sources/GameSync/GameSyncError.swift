public enum GameSyncError: Error {
    case localPlayerNotAuthenticated
    case cannotSyncDifferentPlayersData
    case saveDelegateNotSet
    case saveFileNotFound
}
