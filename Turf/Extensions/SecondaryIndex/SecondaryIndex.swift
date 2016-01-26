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
        self.uniqueName = "index_\(collectionName)"
        self.tableName = "index_\(collectionName)"
        self.properties = properties
    }

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return SecondaryIndexConnection(index: self, connection: connection)
    }
}

extension SecondaryIndex: InstallableExtension {
    public func install(db db: SQLitePtr) {
        let typeErasedProperties = properties.allProperties
        var propertyTypes = ["targetPrimaryKey TEXT NOT NULL UNIQUE", "targetRowId INTEGER"]

        propertyTypes += typeErasedProperties.map { property -> String in
            let nullNotation = property.isNullable ? "" : "NOT NULL"
            return "\(property.name) \(property.sqliteTypeName.rawValue) \(nullNotation)"
        }

        let sql = "CREATE TABLE IF NOT EXISTS `\(tableName)` (\(propertyTypes.joinWithSeparator(",")))"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
        }
    }

    public func uninstall(db db: SQLitePtr) {
        let sql = "DROP TABLE IF EXISTS `\(tableName)`"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
        }
    }
}
