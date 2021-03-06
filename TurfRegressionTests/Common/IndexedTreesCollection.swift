import Foundation

import Turf

final class IndexedTreesCollection: TurfCollection, IndexedCollection {

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

    func serialize(value: Tree) -> Data {
        let dictionaryRepresentation: [String: Any] = [
            "uuid": value.uuid,
            "type": value.type,
            "species": value.species,
            "height": value.height,
            "age": value.age.rawValue
        ]

        return try! JSONSerialization.data(withJSONObject: dictionaryRepresentation, options: [])
    }

    func deserialize(data: Data) -> Value? {
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        guard let
            uuid = json["uuid"] as? String,
            let type = json["type"] as? String,
            let species = json["species"] as? String,
            let height = json["height"] as? Int,
            let age = (json["age"] as? Int).flatMap({ TreeAge(rawValue: $0) })
            else {
                return nil
        }
        return Tree(uuid: uuid, type: type, species: species, height: height, age: age)
    }

    func setUp<Collections>(using transaction: ReadWriteTransaction<Collections>) throws {
        try transaction.register(collection: self)
        try transaction.register(extension: index)
    }

    struct IndexedProperties: Turf.IndexedProperties {

        let type = IndexedProperty<IndexedTreesCollection, String>(name: "type") { tree in
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
