internal class SecondaryIndexConnection<TCollection: TurfCollection, Properties: IndexedProperties>: ExtensionConnection {
    // MARK: Internal properties

    internal unowned let index: SecondaryIndex<TCollection, Properties>

    internal var insertStmt: OpaquePointer!
    internal var updateStmt: OpaquePointer!
    internal var removeStmt: OpaquePointer!
    internal var removeAllStmt: OpaquePointer!

    // MARK: Private properties

    // MARK: Object lifecycle

    internal init(index: SecondaryIndex<TCollection, Properties>) {
        self.index = index
    }

    deinit {
        if let stmt = insertStmt { sqlite3_finalize(stmt) }
        if let stmt = updateStmt { sqlite3_finalize(stmt) }
        if let stmt = removeStmt { sqlite3_finalize(stmt) }
        if let stmt = removeAllStmt { sqlite3_finalize(stmt) }
    }

    // MARK: Internal methods

    func writeTransaction<DatabaseCollections: CollectionsContainer>(_ transaction: ReadWriteTransaction<DatabaseCollections>) -> ExtensionWriteTransaction {
        return SecondaryIndexWriteTransaction(connection: self)
    }

    func prepare(_ db: SQLitePtr) throws {
        try prepareInsertStmt(db: db)
        try prepareUpdateStmt(db: db)
        try prepareRemoveStmt(db: db)
        try prepareRemoveAllStmt(db: db)
    }

    // MARK: Private methods

    fileprivate func prepareInsertStmt(db: SQLitePtr) throws {
        var propertyNames = ["targetPrimaryKey"]
        var propertyBindings = ["?"]

        for property in index.properties.allProperties {
            propertyNames.append(property.name)
            propertyBindings.append("?")
        }

        let sql = "INSERT INTO `\(index.tableName)` (\(propertyNames.joined(separator: ","))) VALUES (\(propertyBindings.joined(separator: ",")))"

        var stmt: OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        insertStmt = stmt
    }

    fileprivate func prepareUpdateStmt(db: SQLitePtr) throws {
        var propertyBindings = [String]()

        for property in index.properties.allProperties {
            propertyBindings.append("\(property.name)=?")
        }

        let sql = "UPDATE `\(index.tableName)` SET \(propertyBindings.joined(separator: ",")) WHERE targetPrimaryKey=?"

        var stmt: OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        updateStmt = stmt
    }

    fileprivate func prepareRemoveStmt(db: SQLitePtr) throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(index.tableName)` WHERE targetPrimaryKey=?;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        removeStmt = stmt
    }

    fileprivate func prepareRemoveAllStmt(db: SQLitePtr) throws {
        var stmt: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, "DELETE FROM `\(index.tableName)`;", -1, &stmt, nil).isOK else {
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
        }

        removeAllStmt = stmt
    }
}
