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
