public extension ReadCollection where TCollection: CollectionWithRelationships {
    var relationships: TCollection.Relationships {
        return self.collection.relationships
    }

    public func destinationValuesInCollection<DCollection: Collection>(
        collection: ReadCollection<DCollection>,
        forRelationship relationship: ToManyRelationshipProperty<TCollection, DCollection>,
        fromSource sourceValue: TCollection.Value) -> [DCollection.Value] {

            var destinationValues: [DCollection.Value] = []
            let _ = relationship.sourceKeyFromSourceValue(sourceValue)
            let destinationKeys = [String]()//Fetch where sourceKey == && relationship == relationship.uniqueName
            for dKey in destinationKeys {
                if let dv = collection.valueForKey(dKey) { destinationValues.append(dv) }
            }
            return destinationValues
    }

    public func destinationKeysForRelationship<DCollection: Collection>(
        relationship: ToManyRelationshipProperty<TCollection, DCollection>,
        fromSource sourceValue: TCollection.Value) -> [String] {

            let _ = relationship.sourceKeyFromSourceValue(sourceValue)
            let destinationKeys = [String]()//Fetch where sourceKey == && relationship == relationship.uniqueName
            return destinationKeys
    }
}
