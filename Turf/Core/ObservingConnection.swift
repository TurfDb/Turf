public final class ObservingConnection<Collections: CollectionsContainer> {
    // MARK: Internal properties

    let connection: Connection<Collections>

    // MARK: Private properties

    private let shouldAdvanceWhenDatabaseChanges: () -> Bool
    private var observableCollections: [String: TypeErasedObservableCollection]
    private var collectionUpdateProcessors: [String: (ReadTransaction<Collections>, ChangeSet<String>) -> Void]

    private var longLivedReadTransaction: ReadTransaction<Collections>!
    private var pendingChangeSets: [[String: ChangeSet<String>]]

    // MARK: Object lifecycle

    internal init(connection: Connection<Collections>, shouldAdvanceWhenDatabaseChanges: () -> Bool) throws {
        self.connection = connection
        self.shouldAdvanceWhenDatabaseChanges = shouldAdvanceWhenDatabaseChanges
        self.observableCollections = [:]
        self.collectionUpdateProcessors = [:]
        self.pendingChangeSets = []

        try self.advanceToLatestSnapshot(changeSets: [:])
    }

    deinit {
        let _ = try? Dispatch.synchronouslyOn(connection.connectionQueue) {
            if let longLivedReadTransaction = self.longLivedReadTransaction {
                try self.connection.postReadTransaction(longLivedReadTransaction)
            }
        }
    }

    // MARK: Public methods

    /**
     - note:
     Thread safe.
     */
    @warn_unused_result
    public func observe<TCollection: Collection>(collection collection: TCollection) -> ObservableCollection<TCollection, Collections> {
        var returnedObserable: ObservableCollection<TCollection, Collections>!

        Dispatch.synchronouslyOn(self.connection.connectionQueue) {
            guard self.observableCollections[collection.name] == nil else {
                returnedObserable = self.observableCollections[collection.name]  as! ObservableCollection<TCollection, Collections>
                return
            }

            returnedObserable =
                ObservableCollection(collectionChangedObservable: Observable.create { [unowned self] observer in
                    self.collectionUpdateProcessors[collection.name] = { transaction, changeSet in
                        let readCollection = transaction.readOnly(collection)
                        observer.handle(next: (readCollection, changeSet))
                    }

                    return BasicDisposable { [weak self] in
                        self?.collectionUpdateProcessors[collection.name] = nil
                    }
                }, collection: self.longLivedReadTransaction.readOnly(collection))


            self.observableCollections[collection.name] = returnedObserable
        }
        
        return returnedObserable
    }


    /**
     - note:
     Thread safe.
     */
    public func observeCollection<TCollection: Collection>(collection: TCollection) -> ObservableCollection<TCollection, Collections> {
        return observe(collection: collection)
    }

    /**
     - note: 
        - Thread safe
     */
    public func advanceToLatestSnapshot() throws {
        var changeSets = [String: ChangeSet<String>]()

        Dispatch.synchronouslyOn(connection.connectionQueue) {
            for pendingChanges in self.pendingChangeSets {
                for (collectionName, pendingChangeSet) in pendingChanges {
                    if let changeSet = changeSets[collectionName] {
                        changeSet.mergeWithChangeSet(pendingChangeSet)
                    } else {
                        changeSets[collectionName] = pendingChangeSet
                    }
                }
            }
        }

        try advanceToLatestSnapshot(changeSets: changeSets)
    }

    // MARK: Internal methods

    /**
     Calls `shouldAdvanceWhenDatabaseChanges` to check if it should advance the snapshot this connection is on.
     Called after commiting a read-write transaction.

     - parameter changeSets: Map of `collection name` -> `Collection change set`.

     - note:
        - Thread safe due to being called on the write queue.
     - warning: This method should only ever be called from at the end of a commit on the write queue.
     */
    func processModifiedCollections(changeSets changeSets: [String: ChangeSet<String>]) throws {
        assert(connection.database.isOnWriteQueue(), "Must be called from write queue")

        guard shouldAdvanceWhenDatabaseChanges() else {
            pendingChangeSets.append(changeSets)
            return
        }

        try advanceToLatestSnapshot(changeSets: changeSets)
    }

    // MARK: Private methods

    /**
     Ends the current read transaction and immediately begins a new one on the latest snapshot.
     Observers are then updated with the change sets.

     - parameter changeSets: Map of `collection name` -> `Collection change set`.

     - note:
        - Thread safe.
     */
    private func advanceToLatestSnapshot(changeSets changeSets: [String: ChangeSet<String>]) throws  {
        try Dispatch.synchronouslyOn(connection.connectionQueue) {
            self.pendingChangeSets = []

            // End previous read transaction
            if let longLivedReadTransaction = self.longLivedReadTransaction {
                try self.connection.postReadTransaction(longLivedReadTransaction)
            }

            // Start new read transaction
            let readTransaction = ReadTransaction(connection: self.connection)
            self.longLivedReadTransaction = readTransaction
            try self.connection.preReadTransaction(readTransaction)

            // Update observers
            for collectionName in self.observableCollections.keys {
                if let updateProcessor = self.collectionUpdateProcessors[collectionName],
                       changeSet = changeSets[collectionName] {
                    updateProcessor(readTransaction, changeSet)
                }
            }

        }
    }
}
