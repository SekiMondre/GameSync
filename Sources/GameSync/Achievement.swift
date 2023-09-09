import GameKit

public struct Achievement: Equatable, Codable {
    
    public var identifier: String
    public var percentComplete: Double = 100
//    public var isCompleted: Bool = false
    
    public init(identifier: String, percentComplete: Double = 100) {
        self.identifier = identifier
        self.percentComplete = percentComplete
    }
    
    init(gkAchievement: GKAchievement) {
        self.identifier = gkAchievement.identifier
        self.percentComplete = gkAchievement.percentComplete
    }
    
    var gkAchievement: GKAchievement {
        let gk = GKAchievement(identifier: identifier)
        gk.percentComplete = percentComplete
        return gk
    }
}

extension Achievement: DoubleComparable {
    public var doubleValue: Double {
        percentComplete
    }
}
