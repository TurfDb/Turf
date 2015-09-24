internal class FTSWriteTransaction<TCollection: Collection, Properties: FTSProperties>: ExtensionWriteTransaction {
    // MARK: Internal properties

    // MARK: Private properties

    private unowned let connection: FTSConnection<TCollection, Properties>
    private unowned let transaction: ReadWriteTransaction

    // MARK: Object lifecycle

    internal init(connection: FTSConnection<TCollection, Properties>, transaction: ReadWriteTransaction) {
        self.connection = connection
        self.transaction = transaction
    }

    // MARK: Internal methods

    func handleValueInsertion<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, rowId: Int64, inCollection collection: TCollection) {

    }

    func handleValueUpdate<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, rowId: Int64, inCollection collection: TCollection) {

    }

    func handleRemovalOfAllRowsInCollection<TCollection : Collection>(collection: TCollection) {

    }

    func handleRemovalOfRowsWithKeys<TCollection : Collection>(primaryKeys: [String], inCollection collection: TCollection) {
        
    }
}