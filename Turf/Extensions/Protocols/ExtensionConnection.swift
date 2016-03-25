/**
 Connection container for an extension.
 Each new database connection will create an ExtensionConnection object for registered extensions.
 */
public protocol ExtensionConnection {
    /**
     Can be used to prepare any sqlite3_stmts for better performance
     */
    func prepare(db: SQLitePtr) throws

    /**
     Factory to create a new write transaction to process collection modifications
     - parameter transaction: Read-write transaction
     - returns: An extension's write transaction
     */
    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction
}
