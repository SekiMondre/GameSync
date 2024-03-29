
public protocol DoubleComparable {
    var doubleValue: Double { get }
}

infix operator ~>

infix operator <~

func ~><A: LeaderboardEntry, B: LeaderboardEntry>(_ lhs: A, _ rhs: B) -> Bool {
    return lhs.ranksHigherThan(rhs)
}

func <~<A: LeaderboardEntry, B: LeaderboardEntry>(_ lhs: A, _ rhs: B) -> Bool {
    return rhs.ranksHigherThan(lhs)
}

func ~><A: DoubleComparable, B: DoubleComparable>(_ lhs: A, _ rhs: B) -> Bool {
    return lhs.doubleValue > rhs.doubleValue
}

func <~<A: DoubleComparable, B: DoubleComparable>(_ lhs: A, _ rhs: B) -> Bool {
    return lhs.doubleValue < rhs.doubleValue
}

struct DiffNullables<A,B> {
    
    let a: A?
    let b: B?
    
    init(_ a: A?, _ b: B?) {
        self.a = a
        self.b = b
    }
    
    func diff(_ both: (A,B) async throws -> Void, onlyA: (A) async throws -> Void, onlyB: (B) async throws -> Void) async rethrows {
        if let a, let b {
            try await both(a,b)
        } else if let a {
            try await onlyA(a)
        } else if let b {
            try await onlyB(b)
        }
    }
}
