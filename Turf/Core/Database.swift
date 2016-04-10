import Foundation

private let databaseWriteQueueKey = "databaseWriteQueueKey".UTF8String

public final class Database<DatabaseCollections: CollectionsContainer> {
    // MARK: Public properties

    //TODO static
    public let CollectionChangedNotification = "TurfCollectionChanged"
    public let CollectionChangedNotificationChangeSetKey = "ChangeSet"

    /// Database file url
    public let url: NSURL

    // MARK: Internal properties

    /// Map of extensions used *only* to guarantee unique naming of extensions
    internal private(set) var extensions: [String: Extension]

    // MARK: Private properties

    private let collections: DatabaseCollections
    private var registeredCollectionNames: [String]
    private var connections: [Int: WeakBox<Connection<DatabaseCollections>>]
    private var observingConnections: [Int: WeakBox<ObservingConnection<DatabaseCollections>>]
    private var lastConnectionId: Int
    private var cacheUpdatesBySnapshot: [UInt64: [String: TypeErasedCacheUpdates]]
    private var minCacheUpdatesSnapshot: UInt64

    private let databaseWriteQueue: Dispatch.Queue
    private let connectionSetUpQueue: Dispatch.Queue
    private var connectionManipulationLock: OSSpinLock = OS_SPINLOCK_INIT
    private var collectionRegistrationLock: OSSpinLock = OS_SPINLOCK_INIT
    private var extensionRegisterationLock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Object lifecycle

    /**
    Instantiate a database. This will create a file at the path if one does not exist.
    - parameter path: Path to where the database should be stored
    - parameter collections: Container of collections associated with this database
     - throws: Any error thrown during `collections.setUpCollections(transaction:)` or one of `SQLiteError.FailedToOpenDatabase` or `SQLiteError.Error(code, reason)` if the database failed to open.
    */
    public convenience init(path: String, collections: DatabaseCollections) throws {
        try self.init(url: NSURL(string: path)!, collections: collections)
    }

    /**
     Instantiate a database. This will create a file at the url if one does not exist.
     - parameter url: Url to where the database should be stored
     - parameter collections: Container of collections associated with this database
     - throws: Any error thrown during `collections.setUpCollections(transaction:)` or one of `SQLiteError.FailedToOpenDatabase` or `SQLiteError.Error(code, reason)` if the database failed to open.
     */
    public init(url: NSURL, collections: DatabaseCollections) throws {
        self.url = url
        self.collections = collections
        self.extensions = [:]
        self.registeredCollectionNames = []
        self.connections = [:]
        self.observingConnections = [:]
        self.lastConnectionId = 0
        self.cacheUpdatesBySnapshot = [:]
        self.minCacheUpdatesSnapshot = 0
        self.databaseWriteQueue = Dispatch.Queues.create(.SerialQueue, name: "turf.database.write-queue")
        self.connectionSetUpQueue = Dispatch.Queues.create(.SerialQueue, name: "turf.database.setup-queue")

        Dispatch.Queues.setContext(
            Dispatch.Queues.makeContext(self.databaseWriteQueue),
            key: databaseWriteQueueKey,
            forQueue: self.databaseWriteQueue)

        try setUpCollections(collections)
    }

    deinit {
        
    }

    // MARK: Public methods

    /**
     Create a new connection to the database.
     - note:
         - Thread safe
             - Uses a fast spin lock opening and closing sqlite connections.
             - Downside is some wasted CPU cycles, but you should not be creating/destroying many connections anyway.
     - returns: A new sqlite database connection
     - throws: `SQLiteError.FailedToOpenDatabase` or `SQLiteError.Error(code, reason)`
    */
    public func newConnection() throws -> Connection<DatabaseCollections> {
        defer { OSSpinLockUnlock(&connectionManipulationLock) }

        // Since `Connection(...)` can throw, it will dealloc immediately triggering a `deinit`
        // This will call `removeConnection(:)` below and cause a deadlock. Therefore we have to
        // init the connection outside of the spin lock.
        OSSpinLockLock(&connectionManipulationLock)
            let nextConnectionId = lastConnectionId + 1
        OSSpinLockUnlock(&connectionManipulationLock)

        let connection = try Connection(id: nextConnectionId, database: self, databaseWriteQueue: databaseWriteQueue)

        OSSpinLockLock(&connectionManipulationLock)
            //TODO Tidy up connections on deinit of Connection
            connections[nextConnectionId] = WeakBox(value: connection)
            lastConnectionId = nextConnectionId

        return connection
    }

    public func newObservingConnection(shouldAdvanceWhenDatabaseChanges shouldAdvanceWhenDatabaseChanges: () -> Bool = { return true }) throws -> ObservingConnection<DatabaseCollections> {
        let connection = try newConnection()

        defer { OSSpinLockUnlock(&connectionManipulationLock) }
        OSSpinLockLock(&connectionManipulationLock)

        let observingConnection = ObservingConnection<DatabaseCollections>(
            connection: connection, shouldAdvanceWhenDatabaseChanges: shouldAdvanceWhenDatabaseChanges)

        observingConnections[connection.id] = WeakBox(value: observingConnection)

        return observingConnection
    }

    // MARK: Internal methods

    /**
     Stop retaining a sqlite3_t database connection. This will NOT close the connection.
     - requires: The connection must be closed before calling this method
     - precondition: `connection.isClosed == true`
     - note:
         - Thread safe
             - Uses a fast spin lock opening and closing sqlite connections.
             - Downside is some wasted CPU cycles, but you should not be creating/destroying many connections anyway.
     - parameter connection: A uniquely named database collection to register.
     */
    func removeConnection(connection: Connection<DatabaseCollections>) {
        precondition(connection.isClosed, "Connection must be closed before removing")

        defer { OSSpinLockUnlock(&connectionManipulationLock) }
        OSSpinLockLock(&connectionManipulationLock)

        connections.removeValueForKey(connection.id)
    }

    /**
     Register a new collection. This ensures the collection name has not already been used.
     - precondition: `collection.name` has not already been registered.
     - note: 
        - Thread safe
            - Uses a spin lock for thread safe registration and unregistration of collections.
     - parameter collection: A uniquely named database collection to register.
     */
    func registerCollection<TCollection: Collection>(collection: TCollection) {
        precondition(!registeredCollectionNames.contains(collection.name),
            "Collection '\(collection.name)' already registered")

        defer { OSSpinLockUnlock(&collectionRegistrationLock) }
        OSSpinLockLock(&collectionRegistrationLock)

        registeredCollectionNames.append(collection.name)
    }

    /**
     Register a new extension. This only ensures each extension has a unique name.
     - precondition: `ext.uniqueName` has not already been registered.
     - note:
        - Thread safe
            - Uses a spin lock for thread safe registration and unregistration of extensions.
     - parameter ext: A uniquely named database extension to register.
     */
    func registerExtension(ext: Extension) {
        precondition(extensions[ext.uniqueName] == nil,
            "Extension '\(ext.uniqueName)' already registered")

        defer { OSSpinLockUnlock(&extensionRegisterationLock) }
        OSSpinLockLock(&extensionRegisterationLock)

        extensions[ext.uniqueName] = ext
    }
    
    /**
     Record changes to a collection made on a snapshot. These changes will be used to update other open connections' caches before starting new transactions.
     - note:
        - Thread safe
     - warning: Must be called from the write queue
     */
    func recordPendingCacheUpdates<Value>(updates: CacheUpdates<String, Value>, onSnapshot snapshot: UInt64, forCollectionNamed collectionName: String) {
        assert(isOnWriteQueue(), "Must be called from write queue")

        defer { OSSpinLockUnlock(&connectionManipulationLock) }
        OSSpinLockLock(&connectionManipulationLock)

        if var cacheUpdatesByCollection = cacheUpdatesBySnapshot[snapshot] {
            cacheUpdatesByCollection[collectionName] = updates
        } else {
            var cacheUpdatesByCollection = [String: TypeErasedCacheUpdates]()
            cacheUpdatesByCollection[collectionName] = updates
            cacheUpdatesBySnapshot[snapshot] = cacheUpdatesByCollection
        }
    }

    /**
     Returns the compacted set of changes for a collection from `minSnapshot` to `maxSnapshot`.
     - note:
         - Thread safe
     */
    func cacheChangesAfterSnapshot<Value>(minSnapshot: UInt64, upToSnapshot maxSnapshot: UInt64, forCollectionNamed collectionName: String) -> CacheUpdates<String, Value> {
        let cacheChanges = CacheUpdates<String, Value>()

        defer { OSSpinLockUnlock(&connectionManipulationLock) }
        OSSpinLockLock(&connectionManipulationLock)

        for snapshot in (minSnapshot + 1) ... maxSnapshot {
            if let cacheUpdatesByCollection = cacheUpdatesBySnapshot[snapshot],
                   updatesForCollection = cacheUpdatesByCollection[collectionName] {
                    cacheChanges.mergeCacheUpdatesFrom(updatesForCollection as! CacheUpdates<String, Value>)
            }
        }

        return cacheChanges
    }

    /**
     - note:
        - Thread safe
            - Safe from connections being added or removed
            - Safe from write transactions recording new changes sets/snapshots
     */
    func removeUnneededCacheUpdates() {
        defer { OSSpinLockUnlock(&connectionManipulationLock) }
        OSSpinLockLock(&connectionManipulationLock)

        //TODO Make cacheUpdatesBySnapshot an optimised (for tail insertion) sorted linked list?

        let lowestConnectionSnapshot =
        connections.values.reduce(UInt64.max) {
            (minConnectionSnapshot, boxedConnection) -> UInt64 in
            guard let connection = boxedConnection.value else { return minConnectionSnapshot }
            return (connection.localSnapshot < minConnectionSnapshot) ? connection.localSnapshot : minConnectionSnapshot
        }

        if lowestConnectionSnapshot != UInt64.max && lowestConnectionSnapshot > minCacheUpdatesSnapshot {
            for snapshot in minCacheUpdatesSnapshot ..< lowestConnectionSnapshot {
                cacheUpdatesBySnapshot.removeValueForKey(snapshot)
            }

            minCacheUpdatesSnapshot = lowestConnectionSnapshot
        }
    }

    func notifyObservingConnectionsOfModifiedCollectionsWithChangeSets(changeSets: [String: ChangeSet<String>]) throws {
        for (_, observingConnection) in observingConnections {
            try observingConnection.value?.processModifiedCollections(changeSets: changeSets)
        }
    }

    func isOnWriteQueue() -> Bool {
        return Dispatch.Queues.queueHasContext(Dispatch.Queues.makeContext(databaseWriteQueue), forKey: databaseWriteQueueKey)
    }

    // MARK: Private methods

    private func setUpCollections(collections: DatabaseCollections) throws {
        let connection = try newConnection()
        try connection.sqlite.setSnapshot(0)

        try connection.readWriteTransaction { transaction in
            try collections.setUpCollections(transaction: transaction)
        }
    }
}
