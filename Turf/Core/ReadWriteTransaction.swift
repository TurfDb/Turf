public final class ReadWriteTransaction<Collections: CollectionsContainer>: ReadTransaction<Collections> {
    // MARK: Public properties

    // MARK: Internal properties

    internal var shouldRollback: Bool

    // MARK: Private properties

    // MARK: Object life cycle

    internal override init(connection: Connection<Collections>) {
        self.shouldRollback = false
        super.init(connection: connection)
    }

    // MARK: Public methods

    /**
     Rollback all changes made in this transaction
     - note:
        - Thread safe
     */
    public func rollback() {
        shouldRollback = true
    }

    /**
     Returns a mutable read-write view of `collection` on the transaction
     - note:
        - Thread safe
     - returns: Read-write view of `collection`
     - parameter collection: The Collection we want a read-write view of
    */
    public func readWrite<TCollection: TurfCollection>(_ collection: TCollection) -> ReadWriteCollection<TCollection, Collections> {
        //TODO Cache 
        return ReadWriteCollection(collection: collection, transaction: self)
    }

    /**
     Register `collection` with the database to create a table.
     - note:
        - Thread safe
     - parameter collection: The Collection we want to register. This creates a table in the database with the same name as the collection's 'name' property
     */
    public func register<TCollection: TurfCollection>(collection: TCollection) throws {
        try SQLiteCollection.createCollectionTableNamed(collection.name, db: connection.sqlite.db)
        connection.database.registerCollection(collection)
    }

    /**
     Register and install (if required) a database extension
     - note:
         - Thread safe
     - parameter extension: An installable extension
     */
    public func register<Ext: Extension>(extension ext: Ext) throws {
        //FIXME segfault
        let localConnection: Connection<Collections> = connection
        try localConnection.registerExtension(ext, onTransaction: self)
    }
}
