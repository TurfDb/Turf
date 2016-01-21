public enum CollectionRowChange<Key> {
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
