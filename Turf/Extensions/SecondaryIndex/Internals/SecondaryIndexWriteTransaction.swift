internal class SecondaryIndexWriteTransaction<IndexedCollection: TurfCollection, Properties: IndexedProperties>: ExtensionWriteTransaction {
    // MARK: Private properties

    private unowned let connection: SecondaryIndexConnection<IndexedCollection, Properties>

    // MARK: Object lifecycle

    internal init(connection: SecondaryIndexConnection<IndexedCollection, Properties>) {
        self.connection = connection
    }

    // MARK: Internal methods

    func handleValueInsertion<TCollection : TurfCollection>(_ value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws {
        //Exensions are allowed to take values from any collection
        //We must force cast the value (to ensure it will crash otherwise) to the same type as the indexed collection's value
        let indexedCollectionValue = value as! Properties.IndexedCollection.Value

        defer { sqlite3_reset(connection.insertStmt) }

        let stmt = connection.insertStmt
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN

        sqlite3_bind_text(stmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)

        let properties = connection.index.properties
        for (index, property) in properties.allProperties.enumerated() {
            property.bindPropertyValue(indexedCollectionValue, toSQLiteStmt: stmt!, atIndex: index + primaryKeyIndex + 1)
        }

        if sqlite3_step(stmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(stmt)
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    func handleValueUpdate<TCollection : TurfCollection>(_ value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws {
        let indexedCollectionValue = value as! Properties.IndexedCollection.Value

        defer { sqlite3_reset(connection.updateStmt) }
        let stmt = connection.updateStmt

        let properties = connection.index.properties
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN + properties.allProperties.count
        sqlite3_bind_text(stmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)

        for (index, property) in properties.allProperties.enumerated() {
            property.bindPropertyValue(indexedCollectionValue, toSQLiteStmt: stmt!, atIndex: index + SQLITE_FIRST_BIND_COLUMN)
        }

        if sqlite3_step(stmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(stmt)
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    func handleRemovalOfAllRowsInCollection<TCollection : TurfCollection>(_ collection: TCollection) throws {
        defer { sqlite3_reset(connection.removeAllStmt) }

        if sqlite3_step(connection.removeAllStmt).isNotDone {
            Logger.log(warning: "SQLite error")
            let db = sqlite3_db_handle(connection.removeAllStmt)
            throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    func handleRemovalOfRowsWithKeys<TCollection : TurfCollection>(_ primaryKeys: [String], inCollection collection: TCollection) throws {
        let primaryKeyIndex = SQLITE_FIRST_BIND_COLUMN

        for primaryKey in primaryKeys {
            sqlite3_bind_text(connection.removeStmt, primaryKeyIndex, primaryKey, -1, SQLITE_TRANSIENT)

            if sqlite3_step(connection.removeStmt).isNotDone {
                Logger.log(warning: "SQLite error")
                let db = sqlite3_db_handle(connection.removeStmt)
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }

            sqlite3_reset(connection.removeStmt)
        }
    }
}
