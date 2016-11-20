internal final class CacheUpdates<Key: Hashable, Value>: TypeErasedCacheUpdates {
    // MARK: Private properties

    fileprivate var valueUpdates: [Key: Value] = [:]
    fileprivate var removedKeys: Set<Key> = []
    fileprivate var allValuesRemoved = false

    // MARK: Internal methods

    func recordValue(_ value: Value, upsertedWithKey key: Key) {
        valueUpdates[key] = value
        removedKeys.remove(key)
    }

    func recordValueRemovedWithKey(_ key: Key) {
        valueUpdates.removeValue(forKey: key)
        removedKeys.insert(key)
    }

    func recordAllValuesRemoved() {
        valueUpdates.removeAll()
        removedKeys.removeAll()
        allValuesRemoved = true
    }

    func resetUpdates() {
        valueUpdates.removeAll(keepingCapacity: true)
        removedKeys.removeAll(keepingCapacity: true)
        allValuesRemoved = false
    }

    func mergeCacheUpdatesFrom(_ otherUpdates: CacheUpdates<Key, Value>) {
        if otherUpdates.allValuesRemoved {
            valueUpdates.removeAll(keepingCapacity: true)
            removedKeys.removeAll(keepingCapacity: true)
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

    func applyUpdatesToCache(_ cache: Cache<Key, Value>) {
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

    func copy() -> CacheUpdates<Key, Value> {
        let cacheUpdates = CacheUpdates()
        cacheUpdates.valueUpdates = self.valueUpdates
        cacheUpdates.removedKeys = self.removedKeys
        cacheUpdates.allValuesRemoved = self.allValuesRemoved
        return cacheUpdates
    }
}

extension CacheUpdates: CustomDebugStringConvertible {
    var debugDescription: String {
        var description = ""

        if valueUpdates.count == 0 && removedKeys.count == 0 && allValuesRemoved == false {
            description = "No cache updates"
        } else {
            description = "Value updates:\n"
            for (key, _) in valueUpdates {
                description += "\t\(key)\n"
            }
            description += "Removed keys:\n"
            for key in removedKeys {
                description += "\t\(key)\n"
            }
            description += "All keys removed: \(allValuesRemoved)\n"
        }

        return description
    }
}

internal protocol TypeErasedCacheUpdates { }
