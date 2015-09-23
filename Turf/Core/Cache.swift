//
//  Cache.swift
//  Turf
//
//  Created by Jordan Hamill on 22/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

internal class Cache<T> {
    private let capacity: Int

    private let mapTable: NSMapTable
    private var mostRecentEntry: CacheEntry<T>?
    private var leastRecentEntry: CacheEntry<T>?
    private var evictedEntry: CacheEntry<T>?

    init(capacity: Int) {
        self.capacity = capacity
        self.mapTable = NSMapTable(keyOptions: .StrongMemory, valueOptions: .StrongMemory)
    }

    subscript(key: String) -> T? {
        get {
            return valueForKey(key)
        }

        set {
            setValue(newValue!, forKey: key)
        }
    }

    func setValue(value: T, forKey key: String) {
        if let existingEntry = mapTable[key] as? CacheEntry<T> {
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
            var entry: CacheEntry<T>

            if let evictedEntry = evictedEntry {
                entry = evictedEntry
                entry.key = key
                entry.value = value

                self.evictedEntry = nil
            } else {
                entry = CacheEntry(key: key, value: value)
            }

            mapTable[key] = entry

            // Add item to beginning of linked-list

            entry.next = mostRecentEntry
            mostRecentEntry?.previous = entry
            mostRecentEntry = entry

            // Evict leastRecentCacheItem if needed

            if capacity > 0 && mapTable.count > capacity {

                leastRecentEntry?.previous?.next = nil

                evictedEntry = leastRecentEntry
                leastRecentEntry = leastRecentEntry?.previous

                if let evictedEntry = evictedEntry {
                    mapTable.removeObjectForKey(evictedEntry.key)

                    evictedEntry.previous = nil
                    evictedEntry.next = nil
                    evictedEntry.key = nil
                    evictedEntry.value = nil
                }

            } else {
                if (leastRecentEntry == nil) {
                    leastRecentEntry = entry
                }
            }
        }
    }

    func valueForKey(key: String) -> T? {
        if let entry = mapTable[key] as? CacheEntry<T> {
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

    func removeValueForKey(key: String) {
        if let entry = mapTable[key] as? CacheEntry<T> {
            entry.previous?.next = entry.next
            entry.next?.previous = entry.previous

            if mostRecentEntry === entry {
                mostRecentEntry = entry.next
            }

            if leastRecentEntry === entry {
                leastRecentEntry = entry.previous
            }
            mapTable.removeObjectForKey(key)
        }
    }

    func removeAllValues() {
        mostRecentEntry = nil
        leastRecentEntry = nil
        evictedEntry = nil
        mapTable.removeAllObjects()
    }
}

internal class CacheEntry<T> {
    var key: String?
    var value: T?

    var previous: CacheEntry<T>? = nil
    var next: CacheEntry<T>? = nil

    init(key: String, value: T) {
        self.key = key
        self.value = value
    }
}

extension NSMapTable {
    subscript(key: AnyObject) -> AnyObject? {
        get {
            return objectForKey(key)
        }

        set {
            if newValue != nil {
                setObject(newValue, forKey: key)
            } else {
                removeObjectForKey(key)
            }
        }
    }
}
