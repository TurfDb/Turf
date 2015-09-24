public extension ReadWriteCollection where TCollection: CollectionWithRelationships {
    // MARK: Public properties

//    public var indexed: TCollection.IndexProperties { return collection.indexed }
//
//    // MARK: Internal properties
//
//    // MARK: Private properties
//
//    // MARK: Public methods
//
//    public func findFirstValueWhere(predicate: String) -> Value? {
//        let connection = extensionConnection()
//        let _ = connection.queryCache.q("SELECT value FROM table \(predicate) LIMIT 1")
//
//
//
//        return nil
//    }
//
//    public func findValuesWhere(predicate: String) -> [Value] {
//        let connection = extensionConnection()
//        let _ = connection.queryCache.q("SELECT value FROM table \(predicate)")
//
//        return []
//    }
//
//    // MARK: Internal methods
//
//    // MARK: Private methods
//
//    private func extensionConnection() -> SecondaryIndexConnection<TCollection, TCollection.IndexProperties> {
//        return readTransaction.connection.connectionForExtension(collection.index) as! SecondaryIndexConnection<TCollection, TCollection.IndexProperties>
//    }

//    public func setValue(value: TCollection.Value, forKey: String, updateRelationships: Bool) {
//        let relationship1 = collection.relationships.toManyRelationships[0] as! ToManyRelationshipProperty
//        let destinationKeys = relationship1.destinationKeysFromSourceValue(value, nil)
//    }

    public func setDestinationKeys<DCollection: Collection>(keys: [String],
        forRelationship relationship: ToManyRelationshipProperty<TCollection, DCollection>,
        fromSource sourceValue: TCollection.Value) {
            let _ = relationship.sourceKeyFromSourceValue(sourceValue)
    }

    public func setDestinationValuesForRelationship<DCollection: Collection>(
        relationship: ToManyRelationshipProperty<TCollection, DCollection>,
        onValue sourceValue: TCollection.Value) {
        let _ = relationship.destinationKeysFromSourceValue(sourceValue, nil)
        let _ = relationship.sourceKeyFromSourceValue(sourceValue)
    }

    public func setDestinationValuesInCollection<DCollection: Collection>(
        destinationCollection: ReadCollection<DCollection>,
        forRelationship relationship: ToManyRelationshipProperty<TCollection, DCollection>,
        fromSource sourceValue: TCollection.Value) {
        let _ = relationship.destinationKeysFromSourceValue(sourceValue, destinationCollection)
        let _ = relationship.sourceKeyFromSourceValue(sourceValue)
    }
}

