import GameKit

public struct Achievement: GameCenterAchievement {
    
    public var identifier: String
    public var percentComplete: Double = 0.0
    public var showsCompletionBanner: Bool = false
    
    public var isCompleted: Bool {
        percentComplete >= 100.0
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public init(gkAchievement: GKAchievement) {
        self.identifier = gkAchievement.identifier
        self.percentComplete = gkAchievement.percentComplete
    }
}
