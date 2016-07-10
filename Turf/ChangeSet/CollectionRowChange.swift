public enum CollectionRowChange<Key: Equatable> {
    case Insert(key: Key)
    case Update(key: Key)
    case Remove(key: Key)

    public var key: Key {
        switch self {
        case .Insert(let key): return key
        case .Update(let key): return key
        case .Remove(let key): return key
        }
    }
}

extension CollectionRowChange: Equatable {
    public var hashValue: Int {
        return 1
    }
}
public func ==<Key: Equatable>(lhs: CollectionRowChange<Key>, rhs: CollectionRowChange<Key>) -> Bool {
    switch (lhs, rhs) {
    case (.Insert(let leftKey), .Insert(let rightKey)): return leftKey == rightKey
    case (.Update(let leftKey), .Update(let rightKey)): return leftKey == rightKey
    case (.Remove(let leftKey), .Remove(let rightKey)): return leftKey == rightKey
    default:
        return false
    }
}

