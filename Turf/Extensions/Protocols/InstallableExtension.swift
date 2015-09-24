/**
 Defines a database extension which can modify the database (e.g. add new tables) registration.
 */
public protocol InstallableExtension: Extension {
    /**
     Called when the extension is registered. 
     - note: It is up to the implementation to handle the connection already having performed the modifications on a previous run.
     - warning: Do no begin/commit/rollback any transactions - a transaction has already been opened for this db and will be commited at a point after `install(db:)`
     - parameter db: sqlite3* pointer which can be used to modify the database.
     */
    func install(db db: SQLitePtr)

    /**
     Called when the extension is unregistered.
     - note: It is up to the implementation to handle the connection already having performed the modifications on a previous run.
     - warning: Do no begin/commit/rollback any transactions - a transaction has already been opened for this db and will be commited at a point after `install(db:)`
     - parameter db: sqlite3* pointer which can be used to modify the database.
     */
    func uninstall(db db: SQLitePtr)
}
