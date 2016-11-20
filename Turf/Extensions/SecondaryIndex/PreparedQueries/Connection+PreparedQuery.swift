extension Connection {
    /**
     Prepare a query for retrieving a single value from `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `Connection` they were created from.
     - parameter collection: Secondary indexed collection where a matching value will be searched for.
     - parameter valueWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(_ collection: TCollection, valueWhere clause: WhereClause) throws -> PreparedValueWhereQuery<Collections> {
        var stmt: OpaquePointer? = nil

        let sql = "SELECT targetPrimaryKey FROM `\(collection.index.tableName)` WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(sqlite.db), String(cString: sqlite3_errmsg(sqlite.db)))
        }

        return PreparedValueWhereQuery(clause: clause, stmt: stmt!, connection: self)
    }

    /**
     Prepare a query for retrieving values from `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `Connection` they were created from.
     - parameter collection: Secondary indexed collection where matching values will be searched for.
     - parameter valuesWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(_ collection: TCollection, valuesWhere clause: WhereClause) throws -> PreparedValuesWhereQuery<Collections> {
        var stmt: OpaquePointer? = nil

        let sql = "SELECT targetPrimaryKey FROM `\(collection.index.tableName)` WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(sqlite.db), String(cString: sqlite3_errmsg(sqlite.db)))
        }

        return PreparedValuesWhereQuery(clause: clause, stmt: stmt!, connection: self)
    }

    /**
     Prepare a query for retrieving a count of values matching `countWhere` in `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `Connection` they were created from.
     - parameter collection: Secondary indexed collection where matching values will be counted.
     - parameter countWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(_ collection: TCollection, countWhere clause: WhereClause) throws -> PreparedCountWhereQuery<Collections> {
        var stmt: OpaquePointer? = nil

        let sql = "SELECT COUNT(targetPrimaryKey) FROM `\(collection.index.tableName)` WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.failedToPrepareStatement(sqlite3_errcode(sqlite.db), String(cString: sqlite3_errmsg(sqlite.db)))
        }

        return PreparedCountWhereQuery(clause: clause, stmt: stmt!, connection: self)
    }
}
