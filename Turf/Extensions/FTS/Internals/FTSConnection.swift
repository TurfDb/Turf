internal class FTSConnection<TCollection: Collection, Properties: FTSProperties>: ExtensionConnection {
    // MARK: Internal properties

    internal unowned let fts: FullTextSearch<TCollection, Properties>

    // MARK: Private properties

    private unowned let connection: Connection

    // MARK: Object lifecycle

    internal init(fts: FullTextSearch<TCollection, Properties>, connection: Connection) {
        self.fts = fts
        self.connection = connection
    }

    // MARK: Internal methods

    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction {
        return FTSWriteTransaction(connection: self, transaction: transaction)
    }

    func prepare(db: SQLitePtr) {

    }
    
    // MARK: Private methods
}
