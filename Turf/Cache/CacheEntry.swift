import Foundation

internal class CacheEntry<Key, Value> {
    // MARK: internal properties

    var key: Key?
    var value: Value?

    var previous: CacheEntry<Key, Value>? = nil
    var next: CacheEntry<Key, Value>? = nil

    // MARK: Object lifecycle

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}
