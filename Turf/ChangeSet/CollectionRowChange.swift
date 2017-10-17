public enum CollectionRowChange<Key: Equatable> {
    case insert(key: Key)
    case update(key: Key)
    case remove(key: Key)

    public var key: Key {
        switch self {
        case .insert(let key): return key
        case .update(let key): return key
        case .remove(let key): return key
        }
    }
}

public func ==<Key>(lhs: CollectionRowChange<Key>, rhs: CollectionRowChange<Key>) -> Bool {
    switch (lhs, rhs) {
    case (.insert(let leftKey), .insert(let rightKey)): return leftKey == rightKey
    case (.update(let leftKey), .update(let rightKey)): return leftKey == rightKey
    case (.remove(let leftKey), .remove(let rightKey)): return leftKey == rightKey
    default:
        return false
    }
}
