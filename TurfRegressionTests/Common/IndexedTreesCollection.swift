import Foundation

import Turf

final class IndexedTreesCollection: Collection, IndexedCollection {

    typealias Value = Tree

    let name = "IndexedTrees"

    let schemaVersion = UInt64(1)

    let valueCacheSize: Int? = nil

    let index: SecondaryIndex<IndexedTreesCollection, IndexedProperties>
    let indexed = IndexedProperties()

    //: We also have to keep a list of extensions that are to be executed on mutation
    let associatedExtensions: [Extension]

    init() {
        index = SecondaryIndex(collectionName: name, properties: indexed, version: 0)
        associatedExtensions = [index]
        index.collection = self
    }

    func serializeValue(value: Tree) -> NSData {
        let dictionaryRepresentation: [String: AnyObject] = [
            "uuid": value.uuid,
            "species": value.species,
            "height": value.height
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dictionaryRepresentation, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])

        guard let
            uuid = json["uuid"] as? String,
            species = json["species"] as? String,
            height = json["height"] as? Int
            else {
                return nil
        }
        return Tree(uuid: uuid, species: species, height: height)
    }

    func setUp(transaction: ReadWriteTransaction) throws {
        try transaction.registerCollection(self)
        try transaction.registerExtension(index)
    }

    struct IndexedProperties: Turf.IndexedProperties {

        let species = IndexedProperty<IndexedTreesCollection, String>(name: "species") { tree -> String in
            return tree.species
        }

        let height = IndexedProperty<IndexedTreesCollection, Int>(name: "height") { tree -> Int in
            return tree.height
        }

        var allProperties: [IndexedPropertyFromCollection<IndexedTreesCollection>] {
            return [
                species.lift(),
                height.lift()
            ]
        }
    }
}
