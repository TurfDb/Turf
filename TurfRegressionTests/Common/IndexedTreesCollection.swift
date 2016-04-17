import Foundation

import Turf

final class IndexedTreesCollection: Collection, IndexedCollection {

    typealias Value = Tree

    let name = "IndexedTrees"

    let schemaVersion = UInt64(1)

    let valueCacheSize: Int? = nil

    let index: SecondaryIndex<IndexedTreesCollection, IndexedProperties>
    let indexed = IndexedProperties()

    let associatedExtensions: [Extension]

    init() {
        index = SecondaryIndex(collectionName: name, properties: indexed, version: 0)
        associatedExtensions = [index]
        index.collection = self
    }

    func serializeValue(value: Tree) -> NSData {
        let dictionaryRepresentation: [String: AnyObject] = [
            "uuid": value.uuid,
            "type": value.type,
            "species": value.species,
            "height": value.height,
            "age": value.age.rawValue
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dictionaryRepresentation, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])

        guard let
            uuid = json["uuid"] as? String,
            type = json["type"] as? String,
            species = json["species"] as? String,
            height = json["height"] as? Int,
            age = json["age"] as? TreeAge
            else {
                return nil
        }
        return Tree(uuid: uuid, type: type, species: species, height: height, age: age)
    }

    func setUp<Collections : CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
        try transaction.registerCollection(self)
        try transaction.registerExtension(index)
    }

    struct IndexedProperties: Turf.IndexedProperties {

        let type = IndexedProperty<IndexedTreesCollection, String>(name: "type") { tree -> String in
            return tree.type
        }

        let species = IndexedProperty<IndexedTreesCollection, String>(name: "species") { tree -> String in
            return tree.species
        }

        let height = IndexedProperty<IndexedTreesCollection, Int>(name: "height") { tree -> Int in
            return tree.height
        }

        let age = IndexedProperty<IndexedTreesCollection, Int>(name: "age") { tree -> Int in
            return tree.age.rawValue
        }

        var allProperties: [IndexedPropertyFromCollection<IndexedTreesCollection>] {
            return [
                type.lift(),
                species.lift(),
                height.lift(),
                age.lift()
            ]
        }
    }
}
