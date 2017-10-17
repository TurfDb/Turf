public extension ReadCollection where TCollection: IndexedCollection {
    // MARK: Public properties

    /// Indexed properties on collection
    public var indexed: TCollection.IndexProperties { return collection.indexed }

    // MARK: Public methods

    /**
     Find the first value that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Value if there is a match
     */
    public func findFirstValue(where clause: WhereClause) -> Value? {
        var firstValue: Value? = nil

        var stmt: OpaquePointer? = nil
        defer { sqlite3_finalize(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            let sql = "SELECT targetPrimaryKey FROM `\(connection.index.tableName)` WHERE \(clause.sql) LIMIT 1"
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
                throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
            }

            _ = try! clause.bindStatements(stmt!, SQLITE_FIRST_BIND_COLUMN)

            let result = sqlite3_step(stmt)
            if result.hasRow {
                if let key = String(stmt: stmt!, columnIndex: SQLITE_FIRST_COLUMN),
                    let fetchedValue = value(for: key) {
                        firstValue = fetchedValue
                }
            } else if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return firstValue
    }

    /**
     Find all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Values that match the predicate
     */
    public func findValues(where clause: WhereClause) -> [Value] {
        var values = [Value]()

        var stmt: OpaquePointer? = nil
        defer { sqlite3_finalize(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            let sql = "SELECT targetPrimaryKey FROM `\(connection.index.tableName)` WHERE \(clause.sql)"
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
                throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
            }

            _ = try! clause.bindStatements(stmt!, SQLITE_FIRST_BIND_COLUMN)

            var result = sqlite3_step(stmt)
            while result.hasRow {
                if let key = String(stmt: stmt!, columnIndex: SQLITE_FIRST_COLUMN), let value = value(for: key) {
                    values.append(value)
                }
                result = sqlite3_step(stmt)
            }

            if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return values
    }

    /**
     Count all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Number of values that match the predicate
     */
    public func countValues(where clause: WhereClause) -> Int {
        var count = 0
        var stmt: OpaquePointer? = nil
        defer { sqlite3_finalize(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            let sql = "SELECT COUNT(targetPrimaryKey) FROM `\(connection.index.tableName)` WHERE \(clause.sql)"
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil).isOK else {
                throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(db), String(cString: sqlite3_errmsg(db)))
            }

            _ = try! clause.bindStatements(stmt!, SQLITE_FIRST_BIND_COLUMN)
            let result = sqlite3_step(stmt)
            if result.hasRow {
                count = Int(sqlite3_column_int64(stmt!, SQLITE_FIRST_COLUMN))
            } else if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return count
    }

    // MARK: Prepared queries

    /**
     Find the first value that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Value if there is a match
     */
    public func findFirstValue(where preparedQuery: PreparedValueWhereQuery<Collections>) -> Value? {
        precondition(preparedQuery.connection === readTransaction.connection,
                     "Prepared queries must be run on the same connection they were created from")

        var firstValue: Value? = nil

        let stmt = preparedQuery.stmt
        defer { sqlite3_reset(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            _ = try! preparedQuery.clause.bindStatements(stmt, SQLITE_FIRST_BIND_COLUMN)

            let result = sqlite3_step(stmt)
            if result.hasRow {
                if let key = String(stmt: stmt, columnIndex: SQLITE_FIRST_COLUMN), let fetchedValue = value(for: key) {
                    firstValue = fetchedValue
                }
            } else if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return firstValue
    }

    /**
     Find all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Values that match the predicate
     */
    public func findValues(where preparedQuery: PreparedValuesWhereQuery<Collections>) -> [Value] {
        precondition(preparedQuery.connection === readTransaction.connection,
                     "Prepared queries must be run on the same connection they were created from")

        var values = [Value]()

        let stmt = preparedQuery.stmt
        defer { sqlite3_reset(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            _ = try! preparedQuery.clause.bindStatements(stmt, SQLITE_FIRST_BIND_COLUMN)

            var result = sqlite3_step(stmt)
            while result.hasRow {
                if let key = String(stmt: stmt, columnIndex: SQLITE_FIRST_COLUMN), let value = value(for: key) {
                    values.append(value)
                }
                result = sqlite3_step(stmt)
            }

            if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return values
    }

    /**
     Count all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Number of values that match the predicate
     */
    public func countValues(where preparedQuery: PreparedCountWhereQuery<Collections>) -> Int {
        precondition(preparedQuery.connection === readTransaction.connection,
                     "Prepared queries must be run on the same connection they were created from")

        var count = 0
        let stmt = preparedQuery.stmt
        defer { sqlite3_reset(stmt) }

        do {
            let connection = extensionConnection()
            let db = sqlite3_db_handle(connection.insertStmt)

            _ = try! preparedQuery.clause.bindStatements(stmt, SQLITE_FIRST_BIND_COLUMN)

            let result = sqlite3_step(stmt)
            if result.hasRow {
                count = Int(sqlite3_column_int64(stmt, SQLITE_FIRST_COLUMN))
            } else if !result.isDone {
                throw SQLiteError.error(code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
            }
        } catch {
            Logger.log(warning: "SQLite error", error)
        }

        return count
    }

    // MARK: Raw SQL queries

    /**
     Find the first value that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Value if there is a match
     */
    public func findFirstValue(where predicate: String) -> Value? {
        return findFirstValue(where: WhereClause(sql: predicate, bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            return 0
        }))
    }

    /**
     Find all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Values that match the predicate
     */
    public func findValues(where predicate: String) -> [Value] {
        return findValues(where: WhereClause(sql: predicate, bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            return 0
        }))
    }

    /**
     Count all values that matches the given predicate using the collection's secondary index
     - parameter where: Query on secondary indexed properties
     - returns: Number of values that match the predicate
     */
    public func countValues(where predicate: String) -> Int {
        return countValues(where: WhereClause(sql: predicate, bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            return 0
        }))
    }

    // MARK: Private methods

    internal func extensionConnection() -> SecondaryIndexConnection<TCollection, TCollection.IndexProperties> {
        //FIXME segfault
        let connection: Connection<Collections> = readTransaction.connection
        return try! connection.connectionForExtension(collection.index) as! SecondaryIndexConnection<TCollection, TCollection.IndexProperties>
    }
}
