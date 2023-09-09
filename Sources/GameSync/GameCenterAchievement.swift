import GameKit

public protocol GameCenterAchievement: DoubleComparable, Equatable, Codable {
    
    var identifier: String { get }
    var percentComplete: Double { get set }
    var showsCompletionBanner: Bool { get set }
    
    init(gkAchievement: GKAchievement)
    func gkAchievement() -> GKAchievement
}

public extension GameCenterAchievement {
    
    func gkAchievement() -> GKAchievement {
        let gk = GKAchievement(identifier: identifier)
        gk.percentComplete = percentComplete
        gk.showsCompletionBanner = showsCompletionBanner
        return gk
    }
    
    var doubleValue: Double {
        percentComplete
    }
}
