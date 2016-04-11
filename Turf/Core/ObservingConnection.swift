public final class ObservingConnection<Collections: CollectionsContainer> {
    // MARK: Internal properties

    let connection: Connection<Collections>

    // MARK: Private properties

    private let shouldAdvanceWhenDatabaseChanges: () -> Bool
    private var observableCollections: [String: TypeErasedObservableCollection]
    private var collectionUpdateProcessors: [String: (ReadTransaction<Collections>, ChangeSet<String>) -> Void]

    private var longLivedReadTransaction: ReadTransaction<Collections>?
    private var pendingChangeSets: [[String: ChangeSet<String>]]

    // MARK: Object lifecycle

    internal init(connection: Connection<Collections>, shouldAdvanceWhenDatabaseChanges: () -> Bool) {
        self.connection = connection
        self.shouldAdvanceWhenDatabaseChanges = shouldAdvanceWhenDatabaseChanges
        self.observableCollections = [:]
        self.collectionUpdateProcessors = [:]
        self.pendingChangeSets = []
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
    public func observeCollection<TCollection: Collection>(collection: TCollection) -> ObservableCollection<TCollection, Collections> {
        let collectionDidChange = { [weak self] (transaction: ReadTransaction<Collections>, changeSet: ChangeSet<String>) in
            guard let strongSelf = self else { return }

            let observableCollection = strongSelf.observableCollections[collection.name] as! ObservableCollection<TCollection, Collections>
            let readCollection = transaction.readOnly(collection)
            observableCollection.processCollectionChanges(readCollection, changeSet: changeSet)
        }

        var observed: ObservableCollection<TCollection, Collections>!

        Dispatch.synchronouslyOn(connection.connectionQueue) {
            if let observedCollection = self.observableCollections[collection.name] as? ObservableCollection<TCollection, Collections> {
                observed = observedCollection
            } else {

                let observedCollection = ObservableCollection<TCollection, Collections>()
                self.observableCollections[collection.name] = observedCollection
                self.collectionUpdateProcessors[collection.name] = collectionDidChange

                observedCollection.disposeBag.add(
                    BasicDisposable { [weak self] in
                        self?.observableCollections.removeValueForKey(collection.name)
                        self?.collectionUpdateProcessors.removeValueForKey(collection.name)
                    }
                )

                //Don't dispose this connection
                observedCollection.disposeBag.parent = nil
                
                observed = observedCollection
            }
        }

        return observed
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
