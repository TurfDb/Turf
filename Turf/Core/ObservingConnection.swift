public final class ObservingConnection {
    // MARK: Private properties

    private let connection: Connection
    private let shouldAdvanceWhenDatabaseChanges: () -> Bool
    private var observableCollections: [String: TypeErasedObservableCollection]
    private var collectionUpdateProcessors: [String: (ReadTransaction, ChangeSet<String>) -> Void]

    private var longLivedReadTransaction: ReadTransaction?
    private var pendingChangeSets: [[String: ChangeSet<String>]]

    // MARK: Object lifecycle

    internal init(connection: Connection, shouldAdvanceWhenDatabaseChanges: () -> Bool) {
        self.connection = connection
        self.shouldAdvanceWhenDatabaseChanges = shouldAdvanceWhenDatabaseChanges
        self.observableCollections = [:]
        self.collectionUpdateProcessors = [:]
        self.pendingChangeSets = []
    }

    deinit {
        Dispatch.synchronouslyOn(connection.connectionQueue) {
            if let longLivedReadTransaction = self.longLivedReadTransaction {
                self.connection.postReadTransaction(longLivedReadTransaction)
            }
        }
    }

    // MARK: Public methods

    /**
     - note: TODO thread safe
     */
    public func observeCollection<TCollection: Collection>(collection: TCollection) -> ObservableCollection<TCollection> {
        if let observedCollection = observableCollections[collection.name] as? ObservableCollection<TCollection> {
            return observedCollection
        } else {
            let collectionDidChange = { [weak self] (transaction: ReadTransaction, changeSet: ChangeSet<String>) in
                guard let strongSelf = self else { return }

                let observableCollection = strongSelf.observableCollections[collection.name] as! ObservableCollection<TCollection>
                let readCollection = collection.readOnly(transaction)
                observableCollection.processCollectionChanges(readCollection, changeSet: changeSet)
            }

            let observedCollection = ObservableCollection<TCollection>()
            observableCollections[collection.name] = observedCollection
            collectionUpdateProcessors[collection.name] = collectionDidChange

            observedCollection.disposeBag.add(
                BasicDisposable { [weak self] in
                    self?.observableCollections.removeValueForKey(collection.name)
                    self?.collectionUpdateProcessors.removeValueForKey(collection.name)
                }
            )

            //Don't dispose this connection
            observedCollection.disposeBag.parent = nil
            
            return observedCollection
        }
    }

    /**
     - note: 
        - TODO thread safe
     */
    public func advanceToLatestSnapshot() {
        var changeSets = [String: ChangeSet<String>]()

        for pendingChanges in pendingChangeSets {
            for (collectionName, pendingChangeSet) in pendingChanges {
                if let changeSet = changeSets[collectionName] {
                    changeSet.mergeWithChangeSet(pendingChangeSet)
                } else {
                    changeSets[collectionName] = pendingChangeSet
                }
            }
        }

        advanceToLatestSnapshot(changeSets: changeSets)
    }

    // MARK: Internal methods 


    /**
     Calls `shouldAdvanceWhenDatabaseChanges` to check if it should advance the snapshot this connection is on.
     Called after commiting a read-write transaction.

     - parameter changeSets: Map of `collection name` -> `Collection change set`.

     - note:
        - TODO Thread safe
     - warning: This method should only ever be called from at the end of a commit on the write queue.
     */
    func processModifiedCollections(changeSets changeSets: [String: ChangeSet<String>]) {
        assert(connection.database.isOnWriteQueue(), "Must be called from write queue")

        guard shouldAdvanceWhenDatabaseChanges() else {
            pendingChangeSets.append(changeSets)
            return
        }

        advanceToLatestSnapshot(changeSets: changeSets)
    }

    // MARK: Private methods

    /**
     Ends the current read transaction and immediately begins a new one on the latest snapshot.
     Observers are then updated with the change sets.

     - parameter changeSets: Map of `collection name` -> `Collection change set`.

     - note:
        - TODO thread safe
     */
    private func advanceToLatestSnapshot(changeSets changeSets: [String: ChangeSet<String>])  {
        pendingChangeSets = []

        Dispatch.asynchronouslyOn(connection.connectionQueue) {
            // End previous read transaction
            if let longLivedReadTransaction = self.longLivedReadTransaction {
                self.connection.postReadTransaction(longLivedReadTransaction)
            }

            let readTransaction = ReadTransaction(connection: self.connection)
            self.longLivedReadTransaction = readTransaction
            // Start new read transaction
            self.connection.preReadTransaction(readTransaction)

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

