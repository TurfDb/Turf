internal class SecondaryIndexConnection<TCollection: Collection, Properties: IndexedProperties>: ExtensionConnection {
    // MARK: Internal properties

    internal unowned let index: SecondaryIndex<TCollection, Properties>

    internal let queryCache: SQLStatementCache

    // MARK: Private properties

    private unowned let connection: Connection

    // MARK: Object lifecycle

    internal init(index: SecondaryIndex<TCollection, Properties>, connection: Connection) {
        self.index = index
        self.connection = connection
        self.queryCache = SQLStatementCache(db: connection.sqlite.db, cacheCapacity: 20)
    }

    // MARK: Internal methods

    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction {
        return SecondaryIndexWriteTransaction(connection: self, transaction: transaction)
    }

    func prepare(db: SQLitePtr) {
    
    }

    // MARK: Private methods
}
