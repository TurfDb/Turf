/**
 Extension to enable secondary indexing one or more properties on a collection
 */
public class SecondaryIndex<TCollection: Collection, Properties: IndexedProperties>: Extension {
    // MARK: Public properties

    public let uniqueName: String

    public let version: UInt64

    public static var turfVersion: UInt64 { return 1 }

    public weak var collection: TCollection?

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

    public func install(transaction: ReadWriteTransaction, db: SQLitePtr, existingInstallationDetails: ExistingExtensionInstallation?) throws {
        let requiresRepopulation = handleExistingInstallation(existingInstallationDetails, db: db)

        let sql = createTableSql()
        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
            return
        }

        if requiresRepopulation {
            repopulate(transaction, collection: collection!)
        }
    }

    public func uninstall(db db: SQLitePtr) throws {
        let sql = "DROP TABLE IF EXISTS `\(tableName)`"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            print("ERROR: TODO HANDLE SOME ERRORS")
        }
    }

    // MARK: Private methods

    private func repopulate(transaction: ReadWriteTransaction, collection: TCollection) {
        let readOnlyCollection = transaction.readOnly(collection)
        let extensionTransaction = newConnection(transaction.connection).writeTransaction(transaction)

        for (key, value) in readOnlyCollection.allKeysAndValues {
            extensionTransaction.handleValueInsertion(value, forKey: key, inCollection: collection)
        }
    }

    private func handleExistingInstallation(existingInstallationDetails: ExistingExtensionInstallation?, db: SQLitePtr) -> Bool {
        let requiresRepopulation = existingInstallationDetails != nil ? (existingInstallationDetails!.version < version) : true

        if requiresRepopulation {
            if sqlite3_exec(db, "DROP TABLE IF EXISTS \(tableName)", nil, nil, nil).isNotOK {
                print("ERROR: TODO HANDLE SOME ERRORS")
                return false
            }
        }

        return requiresRepopulation
    }

    private func createTableSql() -> String {
        let typeErasedProperties = properties.allProperties
        var propertyTypes = ["targetPrimaryKey TEXT NOT NULL UNIQUE"]

        propertyTypes += typeErasedProperties.map { property -> String in
            let nullNotation = property.isNullable ? "" : "NOT NULL"
            return "\(property.name) \(property.sqliteTypeName.rawValue) \(nullNotation)"
        }

        return "CREATE TABLE IF NOT EXISTS `\(tableName)` (\(propertyTypes.joinWithSeparator(",")))"
    }
}
