internal protocol PredicateExpression {
    var sql: String { get }
    var bindStatements: (stmt: COpaquePointer, firstColumnIndex: Int32) throws -> Int32 { get }
}

public class WhereClause: PredicateExpression {
    // MARK: Internal properties

    let sql: String
    let bindStatements: (stmt: COpaquePointer, firstColumnIndex: Int32) throws -> Int32

    // MARK: Object lifecyle

    init(sql: String, bindStatements: (stmt: COpaquePointer, firstColumnIndex: Int32) throws -> Int32) {
        self.sql = sql
        self.bindStatements = bindStatements
    }

    // MARK: Public functions

    public func and(clause: WhereClause) -> WhereClause {
        return WhereClause(sql: "\(sql) AND \(clause.sql)", bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            let selfColumnCount = try self.bindStatements(stmt: stmt, firstColumnIndex: firstColumnIndex)
            let nextColumnIndex = selfColumnCount + firstColumnIndex
            let orColumnCount = try clause.bindStatements(stmt: stmt, firstColumnIndex: nextColumnIndex)
            return selfColumnCount + orColumnCount
        })
    }

    public func or(clause: WhereClause) -> WhereClause {
        return WhereClause(sql: "\(sql) OR \(clause.sql)", bindStatements: { (stmt, firstColumnIndex) -> Int32 in
            let selfColumnCount = try self.bindStatements(stmt: stmt, firstColumnIndex: firstColumnIndex)
            let nextColumnIndex = selfColumnCount + firstColumnIndex
            let orColumnCount = try clause.bindStatements(stmt: stmt, firstColumnIndex: nextColumnIndex)
            return selfColumnCount + orColumnCount
        })
    }
}
