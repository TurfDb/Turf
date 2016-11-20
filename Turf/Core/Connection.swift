public final class Connection<Collections: CollectionsContainer> {
    // MARK: Public properties

    /// Reference to parent database
    public weak var database: Database<Collections>!

    /// Default value cache size when a collection does not provide its own size
    public let defaultValueCacheSize: Int

    // MARK: Internal properties

    /// Id for tracking connections
    internal let id: Int

    /// Wrapper around an open sqlite3 connection
    internal var sqlite: SQLiteAdapter

    /// Has the sqlite connection been closed
    internal var isClosed: Bool { return sqlite.isClosed }

    /// Non-thread safe snapshot number
    internal private(set) var localSnapshot: UInt64

    internal let connectionQueue: DispatchQueue

    // MARK: Private properties

    private let connectionQueueKey = DispatchSpecificKey<Int?>()
    private let databaseWriteQueue: DispatchQueue
    private var connectionModificationLock: OSSpinLock = OS_SPINLOCK_INIT

    private var connectionState: ConnectionState = .inactive
    private var extensionConnections: [String: ExtensionConnection]
    private var collectionsLocalStorage: [String: TypeErasedCollectionLocalStorage]
    private var modifiedCollections: [String: TypeErasedCollection]

    // MARK: Object lifecycle

    /**
     Opens a new connection to the sqlite database.
     - note:
        - This does not have to be instantiated in a thread safe manner
     - parameter id: Unique id for the connection
     - parameter database: Reference (unowned) to the parent Turf database
     - parameter databaseWriteQueue: A common serial queue used for write transactions
     - parameter defaultValueCacheSize: The default when a collection does not provide its own cache size. Default = 50.
     - throws: SQLiteError.FailedToOpenDatabase or SQLiteError.Error(code, reason)
     */
    internal init(id: Int, database: Database<Collections>, databaseWriteQueue: DispatchQueue, defaultValueCacheSize: Int = 50) throws {
        self.id = id
        self.database = database
        self.databaseWriteQueue = databaseWriteQueue
        self.connectionQueue = DispatchQueue(label: "turf.connection[\(id)]")
        self.localSnapshot = 0
        self.defaultValueCacheSize = defaultValueCacheSize
        self.extensionConnections = [:]
        self.collectionsLocalStorage = [:]
        self.modifiedCollections = [:]

        connectionQueue.setSpecific(key: connectionQueueKey, value: id)

        self.sqlite = try SQLiteAdapter(sqliteDatabaseUrl: database.url)
        try self.createExtensionConnections()
    }

    /**
     - note:
        - Thread safe
            - Will not close the sqlite connection until any read/writes have completed
     */
    deinit {
        connectionQueue.sync {
            self.sqlite.close()
        }
        database?.removeConnection(self)
    }

    // MARK: Public methods

    /**
     Pass a new read transaction into `closure` that will be executed asynchronously on a read queue.
     - note:
         - Thread safe
            - `closure` is executed on the connection's queue.
     - parameter closure: Operations to perform within the read transaction.
     */
    public func readTransaction(_ closure: @escaping (ReadTransaction<Collections>, Collections) -> Void) throws {
        try connectionQueue.sync {
            let transaction = ReadTransaction(connection: self)
            try self.preReadTransaction(transaction)
            closure(transaction, self.database.collections)
            try self.postReadTransaction(transaction)
        }
    }

    /**
     Pass a new read-write transaction into `closure` that will be executed asynchronously on the write queue.
     - note:
         - Thread safe
             - `closure` is executed on the connection's queue and global write queue.
     - parameter closure: Operations to perform within the read-write transaction.
     */
    public func readWriteTransaction(_ closure: @escaping (ReadWriteTransaction<Collections>, Collections) throws -> Void) throws {
        try connectionQueue.sync {
            try self.databaseWriteQueue.sync {

                self.databaseWriteQueue.setSpecific(key: connectionQueueKey, value: self.id)

                let transaction = ReadWriteTransaction(connection: self)
                try self.preReadWriteTransaction(transaction)
                try closure(transaction, self.database.collections)
                try self.postReadWriteTransaction(transaction)

                self.databaseWriteQueue.setSpecific(key: connectionQueueKey, value: nil)
            }
        }
    }

    // MARK: Internal methods

    /**
     Register a new extension that must perform an action on first installation. It
     is a fatal error to register an extension twice.
     - note:
         - Thread safe
     - warning: Must be called from a read-write transaction
     */
    func registerExtension<Ext: Extension>(_ ext: Ext, onTransaction transaction: ReadWriteTransaction<Collections>) throws {
        assert(database.isOnWriteQueue(), "Must be called from a read-write transaction")
        self.database.registerExtension(ext)

        var existingInstallation: ExistingExtensionInstallation? = nil
        if let details = sqlite.getDetailsForExtensionWithName(ext.uniqueName) {
            existingInstallation = details
        }

        try ext.install(using: transaction, db: self.sqlite.db, existingInstallationDetails: existingInstallation)

        sqlite.setDetailsForExtension(name: ext.uniqueName, version: ext.version, turfVersion: ext.turfVersion, data: Data())
    }

    /**
     If all extensions have been registered before this connection was created
     there should be no work to do here. If this connection existed while a separate
     connection registered the extension then this will lazily prepare a new connection.
     - note:
         - Weak thread safety
            - Uses spin lock to create connection if required
            - In the average use case this method should do no work so a lightweight synchronization method is required
     - warning: Must be called from a read or read-write transaction
     */
    func connectionForExtension(_ ext: Extension) throws -> ExtensionConnection {
        assert(isOnConnectionQueue(), "Must be called from a read or read-write transaction")
        defer { OSSpinLockUnlock(&connectionModificationLock) }
        OSSpinLockLock(&connectionModificationLock)

        guard let connectionForExtension = extensionConnections[ext.uniqueName] else {
            let connectionForExtension = ext.newConnection(self)
            try connectionForExtension.prepare(self.sqlite.db)
            extensionConnections[ext.uniqueName] = connectionForExtension
            return connectionForExtension
        }
        return connectionForExtension
    }

    /**
     Lazily create local storage required for each collection
     - note:
         - Thread safe
            - Uses spin lock to create local storage if required
            - Creating local storage is a lightweight task and requires a lightweight synchronization method
     */
    func localStorageForCollection<TCollection: TurfCollection>(_ collection: TCollection) -> CollectionLocalStorage<TCollection.Value> {
        defer { OSSpinLockUnlock(&connectionModificationLock) }
        OSSpinLockLock(&connectionModificationLock)

        guard let connectionLocalStorage = collectionsLocalStorage[collection.name] as? CollectionLocalStorage<TCollection.Value> else {

            let valueCacheCapacity = collection.valueCacheSize ?? self.defaultValueCacheSize
            let storage = CollectionLocalStorage<TCollection.Value>(db: sqlite.db, collectionName: collection.name, valueCacheCapactity: valueCacheCapacity)
            collectionsLocalStorage[collection.name] = storage
            return storage
        }

        return connectionLocalStorage
    }

    /**
     Mark a collection as modified
     - note:
        - **Not thread safe**
     - warning: This should be called from the write queue
     */
    func recordModifiedCollection<TCollection: TurfCollection>(_ collection: TCollection) {
        assert(database.isOnWriteQueue(), "Must be called from write queue")
        modifiedCollections[collection.name] = collection
    }

    func isOnConnectionQueue() -> Bool {
        guard let value = DispatchQueue.getSpecific(key: connectionQueueKey) else {
            return false
        }
        return value == self.id
    }

    /**
     - Note:
        **Not thread safe**
     - warning: This must be called from the connection queue.
     */
    func preReadTransaction(_ transaction: ReadTransaction<Collections>) throws {
        assert(isOnConnectionQueue(), "Must be called from a read transaction")

        connectionState = .activeReadTransaction
        try sqlite.beginDeferredTransaction()
        ensureLocalCacheSnapshotConsistency()
    }

    /**
     - Note:
        **Not thread safe**
     - warning: This must be called from the connection queue.
     */
    func postReadTransaction(_ transaction: ReadTransaction<Collections>) throws {
        assert(isOnConnectionQueue(), "Must be called from a read-write transaction")

        try sqlite.commitTransaction()
        database.removeUnneededCacheUpdates()
        connectionState = .inactive
    }

    // MARK: Private methods

    /**
     - Note:
        **Not thread safe**
     - warning: This must be called from the write queue.
     */
    private func preReadWriteTransaction(_ transaction: ReadWriteTransaction<Collections>) throws {
        assert(database.isOnWriteQueue(), "Must be called from write queue")

        connectionState = .activeReadWriteTransaction
        try sqlite.beginDeferredTransaction()
        ensureLocalCacheSnapshotConsistency()
    }

    /**
     - Note:
        **Not thread safe**
     - warning: This must be called from the write queue.
     */
    private func postReadWriteTransaction(_ transaction: ReadWriteTransaction<Collections>) throws {
        assert(database.isOnWriteQueue(), "Must be called from write queue")

        if transaction.shouldRollback {
            try rollbackTransaction(transaction)
            database.notifiyTransactionEnded(wasRolledBack: true)
        } else {
            try commitWriteTransaction(transaction)
            database.notifiyTransactionEnded(wasRolledBack: false)
        }

        database.removeUnneededCacheUpdates()
        connectionState = .inactive
        modifiedCollections = [:]
    }

    /**
     This compares our local snapshot to the sql snapshot before starting a new transaction
     - note:
        - **Not thread safe**
     - warning: This must be called from the connection queue.
     */
    private func ensureLocalCacheSnapshotConsistency() {
        assert(isOnConnectionQueue(), "Must be called from a read or read-write transaction")

        // Calling this SELECT statement causes a read transaction to begin on the db/WAL
        // If the sqlSnapshot that we have a "lock" on is less than our cache snapshot, update the cache to
        // the same point as our sqlite transaction "lock".
        // This can happen when a read (at sql level) happens between a write delivering pending cache updates and sqlite commiting
        let sqlSnapshot = sqlite.databaseSnapshotOnCurrentSqliteTransaction()

        if localSnapshot < sqlSnapshot {
            //TODO What if a collection was added in the last write?
            for (_, collectionLocalStorage) in collectionsLocalStorage {
                collectionLocalStorage
                    .applyChangeSetsToValueCacheAfterSnapshot(localSnapshot, upToSnapshot: sqlSnapshot, withDatabase: database)
            }
            localSnapshot = sqlSnapshot
        }
    }

    /**
     This undos any changes made in the transaction. This will also empty the value cache
     - note:
        - **Not thread safe**
     - warning: This must be called from the write queue.
     */
    private func rollbackTransaction(_ transaction: ReadWriteTransaction<Collections>) throws {
        assert(database.isOnWriteQueue(), "Must be called from write queue")

        try sqlite.rollbackTransaction()
        for collectionLocalStorage in collectionsLocalStorage.values {
            collectionLocalStorage.resetChangeSet()
            collectionLocalStorage.resetValueCache()
            collectionLocalStorage.resetCacheUpdates()
        }
    }

    /**
     This commits any changes made in the transaction and makes these cache changes available to other
     connections. It also notifies any collection observers of the change sets.
     - note:
        - **Not thread safe**
     - warning: This must be called from the write queue.
     */
    private func commitWriteTransaction(_ transaction: ReadWriteTransaction<Collections>) throws {
        assert(database.isOnWriteQueue(), "Must be called from write queue")

        localSnapshot += 1
        try sqlite.setSnapshot(localSnapshot)

        for (name, _) in modifiedCollections {
            let collectionLocalStorage = collectionsLocalStorage[name]!
            collectionLocalStorage.recordPendingCacheUpdatesOnSnapshot(localSnapshot, withDatabase: database)
            collectionLocalStorage.resetCacheUpdates()
        }

        try sqlite.commitTransaction()

        var changeSets = [String: ChangeSet<String>]()
        for (name, collection) in modifiedCollections {
            let collectionLocalStorage = collectionsLocalStorage[name]!
            //TODO Tidy up
            let changeSetCopy = collectionLocalStorage.copyChangeSetFor(collection: collection)
            changeSets[name] = changeSetCopy
            collectionLocalStorage.resetChangeSet()
        }

        try database.notifyObservingConnectionsOfModifiedCollectionsWithChangeSets(changeSets)
    }

    /**
     - note:
        - Thread safe
            - Prepares extension connections on the connection queue
     */
    private func createExtensionConnections() throws {
        try connectionQueue.sync {
            for (uniqueName, ext) in self.database.extensions {
                let connection = ext.newConnection(self)
                try connection.prepare(self.sqlite.db)
                
                self.extensionConnections[uniqueName] = connection
            }
        }
    }
}

private enum ConnectionState {
    case inactive
    case activeReadTransaction
    case activeReadWriteTransaction
}
