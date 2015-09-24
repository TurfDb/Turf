public class FullTextSearch<TCollection: Collection, Properties: FTSProperties>: Extension {
    // MARK: Public properties

    public let uniqueName: String

    // MARK: Internal properties

    internal let tableName: String
    internal let properties: Properties

    // MARK: Object lifecycle

    public init(collectionName: String, properties: Properties) {
        self.uniqueName = "fts-\(collectionName)"

        self.tableName = "fts-\(collectionName)"
        self.properties = properties
    }

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return FTSConnection(fts: self, connection: connection)
    }
}

extension FullTextSearch: InstallableExtension {
    public func install(db db: COpaquePointer) {

    }

    public func uninstall(db db: COpaquePointer) {
        
    }
}
