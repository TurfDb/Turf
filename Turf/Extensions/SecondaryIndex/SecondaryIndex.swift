/**
 Extension to enable secondary indexing one or more properties on a collection
 */
public class SecondaryIndex<TCollection: Collection, Properties: IndexedProperties>: Extension {
    // MARK: Public properties

    public let uniqueName: String

    // MARK: Internal properties

    /// Table name in which the secondary indexed properties are written
    internal let tableName: String

    /// Secondary indexed properties
    internal let properties: Properties

    // MARK: Object lifecycle

    /**
     - parameter collectionName: Name of the collection to secondary index
     - parameter properties: A list of collection properties that will be indexed
     */
    public init(collectionName: String, properties: Properties) {
        self.uniqueName = "index-\(collectionName)"
        self.tableName = "index-\(collectionName)"
        self.properties = properties
    }

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return SecondaryIndexConnection(index: self, connection: connection)
    }
}

extension SecondaryIndex: InstallableExtension {
    public func install(db db: COpaquePointer) {

    }

    public func uninstall(db db: COpaquePointer) {

    }
}
