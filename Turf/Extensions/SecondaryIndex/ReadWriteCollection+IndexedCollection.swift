public extension ReadWriteCollection where TCollection: IndexedCollection {
    // MARK: Public methods

    /**
     Find the first value that matches the given predicate using the collection's secondary index
     - parameter predicate: Query on secondary indexed properties
     - returns: Value if there is a match
     */
    public func removeValuesWhere(_ clause: WhereClause) {
        var stmt: OpaquePointer? = nil
        defer { sqlite3_finalize(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            let selectSql = "SELECT targetPrimaryKey FROM `\(connection.index.tableName)` WHERE \(clause.sql)"
            guard sqlite3_prepare_v2(db, selectSql, -1, &stmt, nil).isOK else {
                throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
            }

            try! clause.bindStatements(stmt!, SQLITE_FIRST_BIND_COLUMN)

            var keysRemoved = [String]()
            var result = sqlite3_step(stmt)
            while result.hasRow {
                if let key = String(stmt: stmt!, columnIndex: SQLITE_FIRST_COLUMN) {
                    keysRemoved.append(key)
                }
                result = sqlite3_step(stmt)
            }

            if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }

            sqlite3_finalize(stmt)
            removeValuesWithKeys(keysRemoved)

            let deleteSql = "DELETE FROM `\(connection.index.tableName)` WHERE \(clause.sql);"
            guard sqlite3_prepare_v2(db, deleteSql, -1, &stmt, nil).isOK else {
                throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
            }

            try! clause.bindStatements(stmt!, SQLITE_FIRST_BIND_COLUMN)
            if sqlite3_step(stmt).isNotDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }
    }
}
