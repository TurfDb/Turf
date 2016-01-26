internal class SecondaryIndexConnection<TCollection: Collection, Properties: IndexedProperties>: ExtensionConnection {
    // MARK: Internal properties

    internal unowned let index: SecondaryIndex<TCollection, Properties>

    internal var insertStmt: COpaquePointer!

    // MARK: Private properties

    private unowned let connection: Connection

    // MARK: Object lifecycle

    internal init(index: SecondaryIndex<TCollection, Properties>, connection: Connection) {
        self.index = index
        self.connection = connection
    }

    // MARK: Internal methods

    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction {
        return SecondaryIndexWriteTransaction(connection: self, transaction: transaction)
    }

    func prepare(db: SQLitePtr) {
        var propertyNames = ["targetPrimaryKey", "targetRowId"]
        var propertyBindings = ["?", "?"]

        for property in index.properties.allProperties {
            propertyNames.append(property.name)
            propertyBindings.append("?")
        }

        let sql = "INSERT INTO `\(index.tableName)` (\(propertyNames.joinWithSeparator(","))) VALUES (\(propertyBindings.joinWithSeparator(",")))"

        //TODO Error handling
        var stmt: COpaquePointer = nil
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isNotOK {
            print("TODO ERROR HANDLING")
        }
        insertStmt = stmt

    }

    // MARK: Private methods
}
