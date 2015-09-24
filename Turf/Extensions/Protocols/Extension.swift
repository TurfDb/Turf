public typealias SQLitePtr = COpaquePointer

/**
 Defines a basic database extension.
 */
public protocol Extension {
    /// Each exension instance must have a unique name
    var uniqueName: String { get }

    /**
     Factory method to create a new connection for the extension.
     - note: A new extension connection is required for each `Turf.Connection`
     - parameter connection: Turf.Connection that can be passed to the extension's connection if required
     - returns: An extension's connection
     */
    func newConnection(connection: Connection) -> ExtensionConnection
}
