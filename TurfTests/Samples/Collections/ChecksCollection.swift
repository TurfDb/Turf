import Foundation
import Turf

final class ChecksCollection: Collection, IndexedCollection, FTSCollection, CollectionWithRelationships {
    typealias Value = Check

    let name = "Checks"
    let schemaVersion = UInt(1)
    let valueCacheSize: Int? = 50

    let index: SecondaryIndex<ChecksCollection, IndexedProperties>
    let indexed = IndexedProperties()

    let fts: FullTextSearch<ChecksCollection, FTSProperties>
    let textProperties = FTSProperties()

    let relationships = Relationships()

    let associatedExtensions: [Extension]

    init() {
        index = SecondaryIndex(collectionName: name, properties: indexed)
        fts = FullTextSearch(collectionName: name, properties: textProperties)
        associatedExtensions = [index]
    }

    func setUp(transaction: ReadWriteTransaction) {
        transaction.registerCollection(self)
        transaction.registerExtension(index)
    }

    func serializeValue(value: Value) -> NSData {
        return NSData()
    }

    func deserializeValue(data: NSData) -> Value? {
        return nil
    }

    struct IndexedProperties: Turf.IndexedProperties {
        let isOpen = IndexedProperty<ChecksCollection, Bool>(name: "isOpen") { return $0.isOpen }
        let name = IndexedProperty<ChecksCollection, String?>(name: "name") { return $0.name }

        var allProperties: [CollectionProperty] {
            return [isOpen, name]
        }
    }

    struct FTSProperties: Turf.FTSProperties {
        let name = FTSProperty<ChecksCollection>(name: "name") { return $0.name ?? "" }

        var allProperties: [FTSProperty<ChecksCollection>] {
            return [name]
        }
    }

    struct Relationships: Turf.RelatedCollections {
        let lineItems = ToManyRelationshipProperty<ChecksCollection, LineItemsCollection>(
            name: "lineItems",
            sourceKeyFromSourceValue: { check -> String in
                return check.uuid
            }, destinationKeysFromSourceValue: { (check, lineItemsCollection) -> [String] in
                return check.lineItemUuids
            })

        var toOneRelationships: [CollectionProperty] {
            return []
        }

        var toManyRelationships: [CollectionProperty] {
            return [lineItems]
        }
    }
}