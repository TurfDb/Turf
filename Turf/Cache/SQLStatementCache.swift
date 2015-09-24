internal class SQLStatementCache {
    typealias SQLiteStmt = COpaquePointer

    enum Error: ErrorType {
        case FailedToPrepareStatement(Int32, String?)
        case FailedToResetStatement(Int32, String?)
    }

    // MARK: Private properties

    private let cache: Cache<String, SQLiteStmt>
    private let db: COpaquePointer

    // MARK: Object lifecyle

    init(db: COpaquePointer, cacheCapacity: Int) {
        self.db = db
        self.cache = Cache(capacity: cacheCapacity)

        self.cache.onEviction = { stmt in
            if let stmt = stmt {
                sqlite3_finalize(stmt)
            }
        }
    }

    deinit {
        assert(!cache.hasEntries, "SQLStatementCache dealloc'd without purging cache")
    }

    // MARK: Internal methods

    func q(query: String) -> SQLiteStmt {
        return try! self.query(key: query, query: query)
    }

    func q(key key: String, query: String) -> SQLiteStmt {
        return try! self.query(key: key, query: query)
    }

    func query(key key: String, query: String) throws -> SQLiteStmt {
        if let cached = cache[key] {
            guard sqlite3_reset(cached).isNotOK else {
                throw Error.FailedToResetStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
            }

            return cached
        } else {
            let stmt = try self.stmt(query, db: db)
            cache[key] = stmt
            return stmt
        }
    }

    func purge() {
        self.cache.removeAllValues { stmt in
            sqlite3_finalize(stmt)
        }
    }

    private func stmt(query: String, db: COpaquePointer) throws -> COpaquePointer {
        var stmt: COpaquePointer = nil

        guard sqlite3_prepare_v2(db, query,  -1, &stmt, nil).isNotOK else {
            throw Error.FailedToPrepareStatement(sqlite3_errcode(db), String.fromCString(sqlite3_errmsg(db)))
        }
        
        return stmt
    }
}
