public enum SecondaryIndexError: ErrorType {
    case IndexTableCreationFailed(code: Int32, reason: String?)
    case IndexTableRemovalFailed(code: Int32, reason: String?)
}

/**
 Extension to enable secondary indexing one or more properties on a collection
 */
public class SecondaryIndex<TCollection: Collection, Properties: IndexedProperties>: Extension {
    // MARK: Public properties

    public let uniqueName: String

    public let version: UInt64

    public static var turfVersion: UInt64 { return 1 }

    /// Required to perform inital/re population of secondary index table
    public weak var collection: TCollection!

    // MARK: Internal properties

    /// Table name of the collection that is indexed
    internal let collectionTableName: String

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
        self.collectionTableName = collectionName
        self.uniqueName = "index_\(collectionName)"
        self.version = version
        self.tableName = "index_\(collectionName)"
        self.properties = properties
    }

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return SecondaryIndexConnection(index: self, connection: connection)
    }

    public func install(transaction: ReadWriteTransaction, db: SQLitePtr, existingInstallationDetails: ExistingExtensionInstallation?) throws {
        let requiresRepopulation = try handleExistingInstallation(existingInstallationDetails, db: db)

        let sql = createTableSql()
        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            throw SecondaryIndexError.IndexTableCreationFailed(
                code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }

        if requiresRepopulation {
            try repopulate(transaction, collection: collection)
        }
    }

    public func uninstall(db db: SQLitePtr) throws {
        let sql = "DROP TABLE IF EXISTS `\(tableName)`"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            throw SecondaryIndexError.IndexTableRemovalFailed(
                code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
        }
    }

    // MARK: Private methods

    private func repopulate(transaction: ReadWriteTransaction, collection: TCollection) throws {
        let readOnlyCollection = transaction.readOnly(collection)
        let extensionTransaction = newConnection(transaction.connection).writeTransaction(transaction)

        for (key, value) in readOnlyCollection.allKeysAndValues {
            try extensionTransaction.handleValueInsertion(value, forKey: key, inCollection: collection)
        }
    }

    private func handleExistingInstallation(existingInstallationDetails: ExistingExtensionInstallation?, db: SQLitePtr) throws -> Bool {
        let requiresRepopulation = existingInstallationDetails != nil ? (existingInstallationDetails!.version < version) : true

        if requiresRepopulation &&
            sqlite3_exec(db, "DROP TABLE IF EXISTS \(tableName)", nil, nil, nil).isNotOK {
                throw SecondaryIndexError.IndexTableRemovalFailed(
                    code: sqlite3_errcode(db), reason: String.fromCString(sqlite3_errmsg(db)))
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
