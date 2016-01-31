/**
 Extension to enable secondary indexing one or more properties on a collection
 */
public class SecondaryIndex<TCollection: Collection, Properties: IndexedProperties>: Extension {
    // MARK: Public properties

    public let uniqueName: String

    public let version: UInt64

    public static var turfVersion: UInt64 { return 1 }

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
    public init(collectionName: String, properties: Properties, version: UInt64) {
        self.uniqueName = "index_\(collectionName)"
        self.version = version
        self.tableName = "index_\(collectionName)"
        self.properties = properties
    }

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return SecondaryIndexConnection(index: self, connection: connection)
    }

    public func install(db db: SQLitePtr, existingInstallationDetails: ExistingExtensionInstallation?) {
        let typeErasedProperties = properties.allProperties
        var propertyTypes = ["targetPrimaryKey TEXT NOT NULL UNIQUE", "targetRowId INTEGER"]

        propertyTypes += typeErasedProperties.map { property -> String in
            let nullNotation = property.isNullable ? "" : "NOT NULL"
            return "\(property.name) \(property.sqliteTypeName.rawValue) \(nullNotation)"
        }

        if let existingInstallationDetails = existingInstallationDetails
            where existingInstallationDetails.version < version {
                if sqlite3_exec(db, "DROP TABLE IF EXISTS \(tableName)", nil, nil, nil).isNotOK {
                    print("ERROR: TODO HANDLE SOME ERRORS")
                    return
                }
        }

        let sql = "CREATE TABLE IF NOT EXISTS `\(tableName)` (\(propertyTypes.joinWithSeparator(",")))"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
            return
        }
    }

    public func uninstall(db db: SQLitePtr) {
        let sql = "DROP TABLE IF EXISTS `\(tableName)`"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
        }
    }
}
