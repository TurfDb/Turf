open class PreparedQuery<Collections: CollectionsContainer> {
    // MARK: Public properties

    open let clause: WhereClause

    // MARK: Internal properties

    let stmt: OpaquePointer
    weak var connection: Connection<Collections>?

    // MARK: Object lifecycle

    init(clause: WhereClause, stmt: OpaquePointer, connection: Connection<Collections>) {
        self.clause = clause
        self.stmt = stmt
        self.connection = connection
    }

    deinit {
        sqlite3_finalize(stmt)
    }
}

open class PreparedValueWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: OpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}

open class PreparedValuesWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: OpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}

open class PreparedCountWhereQuery<Collections: CollectionsContainer>: PreparedQuery<Collections> {
    override init(clause: WhereClause, stmt: OpaquePointer, connection: Connection<Collections>) {
        super.init(clause: clause, stmt: stmt, connection: connection)
    }
}
