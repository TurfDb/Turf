internal class SecondaryIndexConnection<TCollection: Collection, Properties: IndexedProperties>: ExtensionConnection {
    // MARK: Internal properties

    internal unowned let index: SecondaryIndex<TCollection, Properties>

    internal var insertStmt: COpaquePointer!
    internal var updateStmt: COpaquePointer!
    internal var removeStmt: COpaquePointer!
    internal var removeAllStmt: COpaquePointer!

    // MARK: Private properties

    private unowned let connection: Connection

    // MARK: Object lifecycle

    internal init(index: SecondaryIndex<TCollection, Properties>, connection: Connection) {
        self.index = index
        self.connection = connection
    }

    deinit {
        if let stmt = insertStmt { sqlite3_finalize(stmt) }
        if let stmt = updateStmt { sqlite3_finalize(stmt) }
        if let stmt = removeStmt { sqlite3_finalize(stmt) }
        if let stmt = removeAllStmt { sqlite3_finalize(stmt) }
    }

    // MARK: Internal methods

    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction {
        return SecondaryIndexWriteTransaction(connection: self, transaction: transaction)
    }

    func prepare(db: SQLitePtr) throws {
        try prepareInsertStmt(db: db)
        try prepareUpdateStmt(db: db)
        try prepareRemoveStmt(db: db)
        try prepareRemoveAllStmt(db: db)
    }

    // MARK: Private methods

    private func prepareInsertStmt(db db: SQLitePtr) throws {
        var propertyNames = ["targetPrimaryKey"]
        var propertyBindings = ["?"]

        for property in index.properties.allProperties {
            propertyNames.append(property.name)
            propertyBindings.append("?")
        }

        let sql = "INSERT INTO `\(index.tableName)` (\(propertyNames.joinWithSeparator(","))) VALUES (\(propertyBindings.joinWithSeparator(",")))"

        var stmt: COpaquePointer = nil
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        insertStmt = stmt
    }

    private func prepareUpdateStmt(db db: SQLitePtr) throws {
        var propertyBindings = [String]()

        for property in index.properties.allProperties {
            propertyBindings.append("\(property.name)=?")
        }

        let sql = "UPDATE `\(index.tableName)` SET \(propertyBindings.joinWithSeparator(",")) WHERE targetPrimaryKey=?"

        var stmt: COpaquePointer = nil
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        updateStmt = stmt
    }

    private func prepareRemoveStmt(db db: SQLitePtr) throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(index.tableName)` WHERE targetPrimaryKey=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        removeStmt = stmt
    }

    private func prepareRemoveAllStmt(db db: SQLitePtr) throws {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(index.tableName)`;", -1, &stmt, nil).isOK else {
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }

        removeAllStmt = stmt
    }
}
