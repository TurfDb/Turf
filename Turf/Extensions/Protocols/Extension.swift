public typealias SQLitePtr = COpaquePointer

/**
 Defines a basic database extension.
 */
public protocol Extension {
    /// Each exension instance must have a unique name
    var uniqueName: String { get }

    /// Extension instance version number
    var version: UInt64 { get }

    /// Turf extension version number.
    static var turfVersion: UInt64 { get }

    /**
     Factory method to create a new connection for the extension.
     - note: A new extension connection is required for each `Turf.Connection`
     - parameter connection: Turf.Connection that can be passed to the extension's connection if required
     - returns: An extension's connection
     */
    func newConnection(connection: Connection) -> ExtensionConnection

    /**
     Called when the extension is registered.
     - note: It is up to the implementation to handle the connection already having performed the modifications on a previous run.
     - warning: Do no begin/commit/rollback any transactions - a transaction has already been opened for this db and will be commited at a point after `install(db:)`
     - parameter db: sqlite3* pointer which can be used to modify the database.
     */
    func install(transaction: ReadWriteTransaction, db: SQLitePtr, existingInstallationDetails: ExistingExtensionInstallation?)

    /**
     Called when the extension is unregistered.
     - note: It is up to the implementation to handle the connection already having performed the modifications on a previous run.
     - warning: Do no begin/commit/rollback any transactions - a transaction has already been opened for this db and will be commited at a point after `install(db:)`
     - parameter db: sqlite3* pointer which can be used to modify the database.
     */
    func uninstall(db db: SQLitePtr)
}

extension Extension {
    var turfVersion: UInt64 {
        return Self.turfVersion
    }
}
