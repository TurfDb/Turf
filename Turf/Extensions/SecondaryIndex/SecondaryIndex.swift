public enum SecondaryIndexError: Error {
    case indexTableCreationFailed(code: Int32, reason: String?)
    case indexTableRemovalFailed(code: Int32, reason: String?)
}

/**
 Extension to enable secondary indexing one or more properties on a collection
 */
open class SecondaryIndex<TCollection: TurfCollection, Properties: IndexedProperties>: Extension {
    // MARK: Public properties

    open let uniqueName: String

    open let version: UInt64

    open static var turfVersion: UInt64 { return 1 }

    /// Required to perform inital/re population of secondary index table
    open weak var collection: TCollection!

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

    open func newConnection<DatabaseCollections: CollectionsContainer>(_ connection: Connection<DatabaseCollections>) -> ExtensionConnection {
        return SecondaryIndexConnection(index: self)
    }

    open func install<DatabaseCollections: CollectionsContainer>(_ transaction: ReadWriteTransaction<DatabaseCollections>, db: SQLitePtr, existingInstallationDetails: ExistingExtensionInstallation?) throws {
        let requiresRepopulation = try handleExistingInstallation(existingInstallationDetails, db: db)

        let sql = createTableSql()
        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            throw SecondaryIndexError.indexTableCreationFailed(
                code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }

        if requiresRepopulation {
            try repopulate(transaction, collection: collection)
        }
    }

    open func uninstall(db: SQLitePtr) throws {
        //TODO
        let sql = "DROP TABLE IF EXISTS `\(tableName)`"

        if sqlite3_exec(db, sql, nil, nil, nil).isNotOK {
            throw SecondaryIndexError.indexTableRemovalFailed(
                code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: Private methods

    fileprivate func repopulate<DatabaseCollections: CollectionsContainer>(_ transaction: ReadWriteTransaction<DatabaseCollections>, collection: TCollection) throws {
        let readOnlyCollection = transaction.readOnly(collection)
        let extensionTransaction = newConnection(transaction.connection).writeTransaction(transaction)

        for (key, value) in readOnlyCollection.allKeysAndValues {
            try extensionTransaction.handleValueInsertion(value, forKey: key, inCollection: collection)
        }
    }

    fileprivate func handleExistingInstallation(_ existingInstallationDetails: ExistingExtensionInstallation?, db: SQLitePtr) throws -> Bool {
        let requiresRepopulation = existingInstallationDetails != nil ? (existingInstallationDetails!.version < version) : true

        if requiresRepopulation &&
            sqlite3_exec(db, "DROP TABLE IF EXISTS `\(tableName)`", nil, nil, nil).isNotOK {
                throw SecondaryIndexError.indexTableRemovalFailed(
                    code: sqlite3_errcode(db), reason: String(cString: sqlite3_errmsg(db)))
        }

        return requiresRepopulation
    }

    fileprivate func createTableSql() -> String {
        let typeErasedProperties = properties.allProperties
        var propertyTypes = ["targetPrimaryKey TEXT NOT NULL UNIQUE"]

        propertyTypes += typeErasedProperties.map { property -> String in
            let nullNotation = property.isNullable ? "" : "NOT NULL"
            return "`\(property.name)` \(property.sqliteTypeName.rawValue) \(nullNotation)"
        }

        var createIndexes = [createPropertyIndexSql("targetPrimaryKey")]
        createIndexes += typeErasedProperties.map { property in
            return createPropertyIndexSql(property.name)
        }

        return "CREATE TABLE IF NOT EXISTS `\(tableName)` (\(propertyTypes.joined(separator: ",")));"
            + createIndexes.joined(separator: ";")
    }

    fileprivate func createPropertyIndexSql(_ propertyName: String) -> String {
        return "CREATE INDEX IF NOT EXISTS `\(tableName)_\(propertyName)_idx` ON `\(tableName)` (`\(propertyName)`)"
    }
}
