import Foundation

import Turf

final class UnindexedTreesCollection: Collection {

    typealias Value = Tree

    let name = "UnindexedTrees"

    let schemaVersion = UInt64(1)

    let valueCacheSize: Int? = nil

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
    }

//    func setUp<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
//        try transaction.registerCollection(self)
//    }
}
