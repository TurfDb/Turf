internal protocol TypeErasedCollectionLocalStorage {
    /// Prepared sqlite3 statements for interaction with a collection
    var queryCache: Cache<String, String> { get }

    /**
     Removes all values from the value cache
     - note:
        - **Not thread safe**
     */
    func resetValueCache()

    /**
     Empties the change set container
     - note:
        - **Not thread safe**
     */
    func resetChangeSet()

    /**
     Empties the list of cache updates
     - note:
         - **Not thread safe**
     */
    func resetCacheUpdates()

    /**
     Copies the collection's change set.
     - parameter collection: The `object` which the `NSNotification` is posted on. (This **must** be the same collection for which this is the local storage for).
     - returns: A copy of the collection's change set.

     - note:
     - **Not thread safe**
     */
    func copyChangeSetFor(collection: TypeErasedCollection) -> ChangeSet<String>
    
    /**
     Informs `database` of any changes a connection has made to a collection for value cache consistency.
     These changes have not yet made it to a sqlite commit yet.
     Other connections will ask the database to tell them of the most up to date cache information.
     - note:
        - **Not thread safe**
     - parameter snapshot: The connection's snapshot number at which the changes were made
     - parameter database: The database changes were made on
     */
    func recordPendingCacheUpdatesOnSnapshot<DatabaseCollections>(_ snapshot: UInt64, withDatabase database: Database<DatabaseCollections>)

    /**
     Gets all pending and commited cache changes *after* `minSnapshot` up to *and including* `maxSnapshot` from
     `database`. These changes are then applied to the local value cache for consistency.
     - note:
        - **Not thread safe**
     - parameter minSnapshot: Lower bound snapshot number
     - parameter maxSnapshot: upper bound snapshot number
     - parameter database: The database the cache updates were recorded on
     */
    func applyChangeSetsToValueCacheAfterSnapshot<DatabaseCollections>(_ minSnapshot: UInt64, upToSnapshot maxSnapshot: UInt64, withDatabase database: Database<DatabaseCollections>)
}
