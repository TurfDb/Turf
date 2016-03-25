public class PreparedQuery {
    // MARK: Public properties

    public let clause: WhereClause

    // MARK: Internal properties

    let stmt: COpaquePointer
    weak var connection: Connection?

    // MARK: Object lifecycle

    init(clause: WhereClause, stmt: COpaquePointer, connection: Connection) {
        self.clause = clause
        self.stmt = stmt
        self.connection = connection
    }

    deinit {
        sqlite3_finalize(stmt)
    }
}

public class PreparedValueWhereQuery: PreparedQuery { }
public class PreparedValuesWhereQuery: PreparedQuery { }
public class PreparedCountWhereQuery: PreparedQuery { }

extension Connection {
    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, valueWhere clause: WhereClause) throws -> PreparedValueWhereQuery {
        var stmt: COpaquePointer = nil

        let sql = "SELECT targetPrimaryKey FROM \(collection.index.tableName) WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(sqlite.db), String.fromCString(sqlite3_errmsg(sqlite.db)))
        }

        return PreparedValueWhereQuery(clause: clause, stmt: stmt, connection: self)
    }

    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, valuesWhere clause: WhereClause) throws -> PreparedValuesWhereQuery {
        var stmt: COpaquePointer = nil

        let sql = "SELECT targetPrimaryKey FROM \(collection.index.tableName) WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(sqlite.db), String.fromCString(sqlite3_errmsg(sqlite.db)))
        }

        return PreparedValuesWhereQuery(clause: clause, stmt: stmt, connection: self)
    }

    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, countWhere clause: WhereClause) throws -> PreparedCountWhereQuery {
        var stmt: COpaquePointer = nil

        let sql = "SELECT COUNT(targetPrimaryKey) FROM \(collection.index.tableName) WHERE \(clause.sql)"
        guard sqlite3_prepare_v2(sqlite.db, sql, -1, &stmt, nil).isOK else {
            sqlite3_finalize(stmt)
            throw SQLiteError.FailedToPrepareStatement(sqlite3_errcode(sqlite.db), String.fromCString(sqlite3_errmsg(sqlite.db)))
        }

        return PreparedCountWhereQuery(clause: clause, stmt: stmt, connection: self)
    }
}
