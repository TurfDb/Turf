internal protocol PredicateExpression {
    var sql: String { get }
    var bindStatements: (_ stmt: OpaquePointer, _ firstColumnIndex: Int32) throws -> Int32 { get }
}

open class WhereClause: PredicateExpression {
    // MARK: Internal properties

    let sql: String
    let bindStatements: (_ stmt: OpaquePointer, _ firstColumnIndex: Int32) throws -> Int32

    // MARK: Object lifecyle

    init(sql: String, bindStatements: @escaping (_ stmt: OpaquePointer, _ firstColumnIndex: Int32) throws -> Int32) {
        self.sql = sql
        self.bindStatements = bindStatements
    }

    // MARK: Public functions

    open func and(_ clause: WhereClause) -> WhereClause {
        return WhereClause(sql: "(\(sql)) AND (\(clause.sql))", bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            let selfColumnCount = try self.bindStatements(stmt, firstColumnIndex)
            let nextColumnIndex = selfColumnCount + firstColumnIndex
            let orColumnCount = try clause.bindStatements(stmt, nextColumnIndex)
            return selfColumnCount + orColumnCount
        })
    }

    open func or(_ clause: WhereClause) -> WhereClause {
        return WhereClause(sql: "(\(sql)) OR (\(clause.sql))", bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            let selfColumnCount = try self.bindStatements(stmt, firstColumnIndex)
            let nextColumnIndex = selfColumnCount + firstColumnIndex
            let orColumnCount = try clause.bindStatements(stmt, nextColumnIndex)
            return selfColumnCount + orColumnCount
        })
    }
}
