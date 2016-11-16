public final class ReadWriteCollection<TCollection: TurfCollection, Collections: CollectionsContainer>: ReadCollection<TCollection, Collections>, WritableCollection {
    // MARK: Internal properties

    /// Reference to read-write transaction from which this collection operates on
    internal unowned let readWriteTransaction: ReadWriteTransaction<Collections>

    // MARK: Private properties

    /// Work around to stop swift segfaulting when calling self.collection.serializeValue(...)
    private let serializeValue: (Value) -> Data

    // MARK: Object lifecycle

    /**
     - parameter collection: Collection this read-write view wraps
     - parameter transaction: Read-write transaction the read-write view operates on
    */
    internal init(collection: TCollection, transaction: ReadWriteTransaction<Collections>) {
        self.readWriteTransaction = transaction
        self.serializeValue = collection.serializeValue
        super.init(collection: collection, transaction: transaction)
    }

    // MARK: Public methods

    /**
     Set a value in the collection with `key`
     - parameter value: Value
     - parameter key: Primary key for `value`
     */
    public func setValue(_ value: Value, forKey key: String) {
        try! commonSetValue(value, forKey: key)
    }

    /**
     Remove values with the given primary keys
     - parameter keys: Primary keys of the values to remove
     */
    public func removeValuesWithKeys(_ keys: [String]) {
        try! commonRemoveValuesWithKeys(keys)
    }

    /**
     Remove all values in the collection
     */
    public func removeAllValues() {
        try! commonRemoveAllValues()
    }

    // MARK: Private methods

    fileprivate func commonSetValue(_ value: Value, forKey key: String) throws -> SQLiteRowChangeType {
        let valueData = serializeValue(value)

        let rowChange = try localStorage.sql.setValueData(valueData, valueSchemaVersion: schemaVersion, forKey: key)
        switch rowChange {
        case .insert(_): localStorage.changeSet.recordValueInsertedWithKey(key)
        case .update(_): localStorage.changeSet.recordValueUpdatedWithKey(key)
        }
        localStorage.valueCache[key] = value
        localStorage.cacheUpdates.recordValue(value, upsertedWithKey: key)

        //FIXME segfault
        let connection: Connection<Collections> = readWriteTransaction.connection
        connection.recordModifiedCollection(collection)
        return rowChange
    }

    fileprivate func commonRemoveValuesWithKeys(_ keys: [String]) throws {
        for key in keys {
            try localStorage.sql.removeValueWithKey(key)
            localStorage.valueCache.removeValueForKey(key)
            localStorage.changeSet.recordValueRemovedWithKey(key)
            localStorage.cacheUpdates.recordValueRemovedWithKey(key)
        }
        //FIXME segfault
        let connection: Connection<Collections> = readWriteTransaction.connection
        connection.recordModifiedCollection(collection)
    }

    fileprivate func commonRemoveAllValues() throws {
        try localStorage.sql.removeAllValues()
        localStorage.valueCache.removeAllValues()
        localStorage.changeSet.recordAllValuesRemoved()
        localStorage.cacheUpdates.recordAllValuesRemoved()
        //FIXME segfault
        let connection: Connection<Collections> = readWriteTransaction.connection
        connection.recordModifiedCollection(collection)
    }
}

public extension ReadWriteCollection where TCollection: ExtendedCollection {
    /**
     Set a value in the collection with `key`
     - note: Executes any associated extensions
     - parameter value: Value
     - parameter key: Primary key for `value`
     */
    public func setValue(_ value: Value, forKey key: String) {
        let rowChange: SQLiteRowChangeType = try! commonSetValue(value, forKey: key)
        
        let connection = readWriteTransaction.connection
        switch rowChange {
        case .insert(_):
            for ext in collection.associatedExtensions {
                //TODO Aggregate try! errors and throw at a commit level
                let extConnection = try! connection.connectionForExtension(ext)
                let extTransaction = extConnection.writeTransaction(readWriteTransaction)

                try! extTransaction.handleValueInsertion(value, forKey: key, inCollection: collection)
            }

        case .update(_):
            for ext in collection.associatedExtensions {
                let extConnection = try! connection.connectionForExtension(ext)
                //TODO Investigate the potential of caching extension write transactions on the connection
                let extTransaction = extConnection.writeTransaction(readWriteTransaction)

                try! extTransaction.handleValueUpdate(value, forKey: key, inCollection: collection)
            }
        }
    }

    /**
     Remove values with the given primary keys
     - note: Executes any associated extensions
     - parameter keys: Primary keys of the values to remove
     */
    public func removeValuesWithKeys(_ keys: [String]) {
        try! commonRemoveValuesWithKeys(keys)

        let connection = readWriteTransaction.connection
        for ext in collection.associatedExtensions {
            let extConnection = try! connection.connectionForExtension(ext)
            let extTransaction = extConnection.writeTransaction(readWriteTransaction)

            try! extTransaction.handleRemovalOfRowsWithKeys(keys, inCollection: collection)
        }
    }

    /**
     Remove all values in the collection
     - note: Executes any associated extensions
     */
    public func removeAllValues() {
        try! commonRemoveAllValues()

        let connection = readWriteTransaction.connection
        for ext in collection.associatedExtensions {
            let extConnection = try! connection.connectionForExtension(ext)
            let extTransaction = extConnection.writeTransaction(readWriteTransaction)

            try! extTransaction.handleRemovalOfAllRowsInCollection(collection)
        }
    }
}
