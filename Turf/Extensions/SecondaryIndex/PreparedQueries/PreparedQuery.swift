public class PreparedQuery<Collections: CollectionsContainer> {
    // MARK: Public properties

    public let clause: WhereClause

    // MARK: Internal properties

    let stmt: COpaquePointer
    weak var connection: Connection<Collections>?

    // MARK: Object lifecycle

    init(clause: WhereClause, stmt: COpaquePointer, connection: Connection<Collections>) {
        self.clause = clause
        self.stmt = stmt
        self.connection = connection
    }

    deinit {
        sqlite3_finalize(stmt)
    }
}

public class PreparedValueWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: COpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}

public class PreparedValuesWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: COpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}

public class PreparedCountWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: COpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}
