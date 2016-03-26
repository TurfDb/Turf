internal class SecondaryIndexWriteTransaction<IndexedCollection: Collection, Properties: IndexedProperties>: ExtensionWriteTransaction {
    // MARK: Private properties

    private unowned let connection: SecondaryIndexConnection<IndexedCollection, Properties>
    private unowned let transaction: ReadWriteTransaction

    // MARK: Object lifecycle

    internal init(connection: SecondaryIndexConnection<IndexedCollection, Properties>, transaction: ReadWriteTransaction) {
        self.connection = connection
        self.transaction = transaction
    }

    // MARK: Internal methods

    func handleValueInsertion<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws {
        //Exensions are allowed to take values from any collection
        //We must force cast the value (to ensure it will crash otherwise) to the same type as the indexed collection's value
        let indexedCollectionValue = value as! Properties.IndexedCollection.Value

        defer { sqlite3_reset(connection.insertStmt) }

        let stmt = connection.insertStmt
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN

        sqlite3_bind_text(stmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)

        let properties = connection.index.properties
        for (index, property) in properties.allProperties.enumerate() {
            property.bindPropertyValue(indexedCollectionValue, toSQLiteStmt: stmt, atIndex: index + primaryKeyIndex + 1)
        }

        if sqlite3_step(stmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(stmt)
            throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    func handleValueUpdate<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws {
        let indexedCollectionValue = value as! Properties.IndexedCollection.Value

        defer { sqlite3_reset(connection.updateStmt) }
        let stmt = connection.updateStmt

        let properties = connection.index.properties
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN + properties.allProperties.count
        sqlite3_bind_text(stmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)***

        for (index, property) in properties.allProperties.enumerate() {
            property.bindPropertyValue(indexedCollectionValue, toSQLiteStmt: stmt, atIndex: index + SQLITE_FIRST_BIND_COLUMN)
        }

        if sqlite3_step(stmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(stmt)
            throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    func handleRemovalOfAllRowsInCollection<TCollection : Collection>(collection: TCollection) throws {
        defer { sqlite3_reset(connection.removeAllStmt) }

        if sqlite3_step(connection.removeAllStmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(connection.removeAllStmt)
            throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    func handleRemovalOfRowsWithKeys<TCollection : Collection>(primaryKeys: [String], inCollection collection: TCollection) throws {
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN

        for primaryKey in primaryKeys {
            sqlite3_bind_text(connection.removeStmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)

            if sqlite3_step(connection.removeStmt).isNotDone {
                Logger.log(warning: "SQLite error")
                let db = sqlite3_db_handle(connection.removeStmt)
                throw SQLiteError.Error(code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
            }

            sqlite3_reset(connection.removeStmt)
        }
    }
}
