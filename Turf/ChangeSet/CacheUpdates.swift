internal final class CacheUpdates<Key: Hashable, Value>: TypeErasedCacheUpdates {
    // MARK: Private properties

    private var valueUpdates: [Key: Value] = [:]
    private var removedKeys: Set<Key> = []
    private var allValuesRemoved = false

    // MARK: Internal methods

    func recordValue(value: Value, upsertedWithKey key: Key) {
        valueUpdates[key] = value
        removedKeys.remove(key)
    }

    func recordValueRemovedWithKey(key: Key) {
        valueUpdates.removeValueForKey(key)
        removedKeys.insert(key)
    }

    func recordAllValuesRemoved() {
        valueUpdates.removeAll()
        removedKeys.removeAll()
        allValuesRemoved = true
    }

    func resetUpdates() {
        valueUpdates.removeAll(keepCapacity: true)
        removedKeys.removeAll(keepCapacity: true)
        allValuesRemoved = false
    }

    func mergeCacheUpdatesFrom(otherUpdates: CacheUpdates<Key, Value>) {
        if otherUpdates.allValuesRemoved {
            valueUpdates.removeAll(keepCapacity: true)
            removedKeys.removeAll(keepCapacity: true)
            allValuesRemoved = true

            for (key, value) in otherUpdates.valueUpdates {
                valueUpdates[key] = value
            }
        } else {
            for removedKey in otherUpdates.removedKeys {
                recordValueRemovedWithKey(removedKey)
            }

            for (key, value) in otherUpdates.valueUpdates {
                recordValue(value, upsertedWithKey: key)
            }
        }
    }

    func applyUpdatesToCache(cache: Cache<Key, Value>) {
        if allValuesRemoved {
            cache.removeAllValues()

            for (key, value) in valueUpdates {
                cache.seValue(value, forKey: key)
            }
        } else {

            for (key, value) in valueUpdates {
                if cache.hasKey(key) {
                    cache.seValue(value, forKey: key)
                }
            }
        }
    }
}

internal protocol TypeErasedCacheUpdates { }
