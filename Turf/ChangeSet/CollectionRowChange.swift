public enum CollectionRowChange<Key> {
    case Insert(key: Key)
    case Update(key: Key)
    case Remove(key: Key)
}
