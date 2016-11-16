import Foundation

/**
 * Cache port from YapDatabase
 */
internal class Cache<Key: Hashable, Value> where Key: Any {

    // MARK: Internal properties

    var onEviction: ((Value?) -> Void)?

    var hasEntries: Bool {
        return container.count > 0
    }

    // MARK: Private properties

    private let capacity: Int

    private var container: [Key: CacheEntry<Key, Value>]
    private var mostRecentEntry: CacheEntry<Key, Value>?
    private var leastRecentEntry: CacheEntry<Key, Value>?
    private var evictedEntry: CacheEntry<Key, Value>?

    // MARK: Object lifecycle

    init(capacity: Int) {
        self.capacity = capacity
        self.container = Dictionary()
    }

    // MARK: Internal methods

    subscript(key: Key) -> Value? {
        get {
            return valueForKey(key)
        }

        set {
            seValue(newValue!, forKey: key)
        }
    }

    func seValue(_ value: Value, forKey key: Key) {
        if let existingEntry = container[key] {
            // Update item value
            existingEntry.value = value

            if existingEntry !== mostRecentEntry {
                // Remove item from current position in linked-list
                //
                // Notes:
                // We fetched the item from the list,
                // so we know there's a valid mostRecentCacheItem & leastRecentCacheItem.
                // Furthermore, we know the item isn't the mostRecentCacheItem.

                existingEntry.previous?.next = existingEntry.next

                if existingEntry === leastRecentEntry {
                    leastRecentEntry = existingEntry.previous
                } else {
                    existingEntry.next?.previous = existingEntry.previous
                }

                // Move item to beginning of linked-list

                existingEntry.previous = nil
                existingEntry.next = mostRecentEntry

                mostRecentEntry?.previous = existingEntry
                mostRecentEntry = existingEntry
            }
        } else {
            var entry: CacheEntry<Key, Value>

            if let evictedEntry = evictedEntry {
                entry = evictedEntry
                entry.key = key
                entry.value = value

                self.evictedEntry = nil
            } else {
                entry = CacheEntry(key: key, value: value)
            }

            container[key] = entry

            // Add item to beginning of linked-list

            entry.next = mostRecentEntry
            mostRecentEntry?.previous = entry
            mostRecentEntry = entry

            // Evict leastRecentCacheItem if needed

            if capacity > 0 && container.count > capacity {

                leastRecentEntry?.previous?.next = nil

                evictedEntry = leastRecentEntry
                leastRecentEntry = leastRecentEntry?.previous

                if let evictedEntry = evictedEntry, let key = evictedEntry.key {
                    container.removeValue(forKey: key)

                    evictedEntry.previous = nil
                    evictedEntry.next = nil
                    evictedEntry.key = nil

                    onEviction?(evictedEntry.value)
                    evictedEntry.value = nil
                }

            } else {
                if (leastRecentEntry == nil) {
                    leastRecentEntry = entry
                }
            }
        }
    }

    func valueForKey(_ key: Key) -> Value? {
        if let entry = container[key] {
            if entry !== mostRecentEntry {
                // Remove item from current position in linked-list.
                //
                // Notes:
                // We fetched the item from the list,
                // so we know there's a valid mostRecentCacheItem & leastRecentCacheItem.
                // Furthermore, we know the item isn't the mostRecentCacheItem.

                entry.previous?.next = entry.next

                if (entry === leastRecentEntry) {
                    leastRecentEntry = entry.previous
                } else {
                    entry.next?.previous = entry.previous
                }

                // Move item to beginning of linked-list

                entry.previous = nil
                entry.next = mostRecentEntry;

                mostRecentEntry?.previous = entry
                mostRecentEntry = entry
            }

            return entry.value
        }
        return nil
    }

    func removeValueForKey(_ key: Key) {
        if let entry = container[key] {
            entry.previous?.next = entry.next
            entry.next?.previous = entry.previous

            if mostRecentEntry === entry {
                mostRecentEntry = entry.next
            }

            if leastRecentEntry === entry {
                leastRecentEntry = entry.previous
            }
            container.removeValue(forKey: key)
        }
    }

    func removeAllValues() {
        mostRecentEntry = nil
        leastRecentEntry = nil
        evictedEntry = nil
        container.removeAll()
    }

    func removeAllValues(_ each: (Value) -> Void) {
        mostRecentEntry = nil
        leastRecentEntry = nil
        evictedEntry = nil

        for (_, entry) in container {
            if let value = entry.value {
                each(value)
            }
        }

        container.removeAll()
    }

    func hasKey(_ key: Key) -> Bool {
        return container[key] != nil
    }
}
