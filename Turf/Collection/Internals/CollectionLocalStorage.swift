internal class CollectionLocalStorage<Value>: TypeErasedCollectionLocalStorage {
    /// Collection primary key type
    typealias Key = String

    // MARK: Internal properties

    let collectionName: String

    /// Prepared sqlite3 statements for interaction with a collection
    let queryCache: Cache<String, String>

    /// Cached deserialized values
    let valueCache: Cache<Key, Value>

    /// Set of changes made to collection
    let changeSet: ChangeSet<Key>

    /// A squashed change set that also tracks the new values - used to update other connections' caches
    let cacheUpdates: CacheUpdates<String, Value>

    let sql: SQLiteCollection

    // MARK: Object lifecycle

    /**
     - parameter valueCacheCapactity: Number of deserialized values to keep in the value cache
     */
    init(db: COpaquePointer, collectionName: String, valueCacheCapactity: Int) {
        self.collectionName = collectionName
        self.queryCache = Cache(capacity: 5)
        self.valueCache = Cache(capacity: valueCacheCapactity)
        self.changeSet = ChangeSet()
        self.cacheUpdates = CacheUpdates()
        self.sql = try! SQLiteCollection(db: db, collectionName: collectionName)
    }

    // MARK: Internal methods

    /**
     Removes all values from the value cache
     - note:
         - **Not thread safe**
     */
    func resetValueCache() {
        valueCache.removeAllValues()
    }

    /**
     Empties the change set container
     - note:
         - **Not thread safe**
     */
    func resetChangeSet() {
        changeSet.resetChangeSet()
    }

    /**
     Empties the list of cache updates
     - note:
        - **Not thread safe**
     */
    func resetCacheUpdates() {
        cacheUpdates.resetUpdates()
    }

    /**
     Notifies collection observers of any changes
     - parameter collection: The `object` which the `NSNotification` is posted on. (This **must** be the same collection for which this is the local storage for).
     - returns: A copy of the collection's change set.

     - note:
         - **Not thread safe**
     */
    func notifyObserversOfChangeSetForCollection(collection: TypeErasedCollection) -> ChangeSet<String> {
        assert(collection.name == collectionName,
            "Incorrect collection - I will refactor CollectionLocalStorage to not allow this...")

        guard changeSet.changes.count > 0 || self.changeSet.allValuesRemoved else { return ChangeSet<String>() }

        let changeSetCopy = self.changeSet.copy()
        Dispatch.asynchronouslyOn(Dispatch.Queues.Main) {
            NSNotificationCenter.defaultCenter()
                .postNotificationName(
                    CollectionChangedNotification,
                    object: collection,
                    userInfo: [
                        CollectionChangedNotificationChangeSetKey: changeSetCopy
                    ])
        }

        return changeSetCopy
    }

    /**
     This method informs `database` of any changes a connection has made to a collection for value cache consistency.
     These changes have not yet made it to a sqlite commit yet.
     Other connections will ask the database to tell them of the most up to date cache information.
     - note:
         - **Not thread safe**
     - parameter database: The database changes were made on
     - parameter snapshot: The connection's snapshot number at which the changes were made
     */
    func recordPendingCacheUpdatesOnSnapshot<DatabaseCollections: CollectionsContainer>(snapshot: UInt64, withDatabase database: Database<DatabaseCollections>) {
        database.recordPendingCacheUpdates(cacheUpdates.copy(), onSnapshot: snapshot, forCollectionNamed: collectionName)
    }

    /**
     Gets all pending and commited cache changes *after* `minSnapshot` up to *and including* `maxSnapshot` from
     `database`. These changes are then applied to the local value cache for consistency.
     - note:
     - **Not thread safe**
     - parameter minSnapshot: Lower bound snapshot number
     - parameter maxSnapshot: upper bound snapshot number
     - parameter database: The database the cache updates were recorded on
     */
    func applyChangeSetsToValueCacheAfterSnapshot<DatabaseCollections: CollectionsContainer>(minSnapshot: UInt64, upToSnapshot maxSnapshot: UInt64, withDatabase database: Database<DatabaseCollections>) {
        let cacheChanges: CacheUpdates<String, Value> = database
            .cacheChangesAfterSnapshot(minSnapshot, upToSnapshot: maxSnapshot, forCollectionNamed: collectionName)
        cacheChanges.applyUpdatesToCache(valueCache)
    }
}
