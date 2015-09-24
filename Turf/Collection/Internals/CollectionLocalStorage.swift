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

    // MARK: Private properties

    // MARK: Object lifecycle

    /**
     - parameter valueCacheCapactity: Number of deserialized values to keep in the value cache
     */
    init(collectionName: String, valueCacheCapactity: Int) {
        self.collectionName = collectionName
        self.queryCache = Cache(capacity: 5)
        self.valueCache = Cache(capacity: valueCacheCapactity)
        self.changeSet = ChangeSet()
        self.cacheUpdates = CacheUpdates()
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
     Noifies collection observers of any changes
     - note:
     - **Not thread safe**
     */
    func notifyCollectionObserversOfChangeSet() {
        
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
    func recordPendingCacheUpdatesOnSnapshot(snapshot: UInt64, withDatabase database: Database){
        database.recordPendingCacheUpdates(cacheUpdates, onSnapshot: snapshot, forCollectionNamed: collectionName)
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
    func applyChangeSetsToValueCacheAfterSnapshot(minSnapshot: UInt64, upToSnapshot: UInt64, withDatabase database: Database) {
        let cacheChanges: CacheUpdates<String, Value> = database
            .cacheChangesAfterSnapshot(minSnapshot, upToSnapshot: upToSnapshot, forCollectionNamed: collectionName)
        cacheChanges.applyUpdatesToCache(valueCache)
    }
}
