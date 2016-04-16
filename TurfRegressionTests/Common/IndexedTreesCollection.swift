import Foundation

final class IndexedTreesCollection: Collection, IndexedCollection {

    typealias Value = Tree

    let name = "IndexedTrees"

    let schemaVersion = UInt64(1)

    let valueCacheSize: Int? = nil

    let index: SecondaryIndex<UsersCollection, IndexedProperties>
    let indexed = IndexedProperties()

    //: We also have to keep a list of extensions that are to be executed on mutation
    let associatedExtensions: [Extension]

    init() {
        index = SecondaryIndex(collectionName: name, properties: indexed, version: 0)
        associatedExtensions = [index]
        index.collection = self
    }

    func serializeValue(value: User) -> NSData {
        let dictionaryRepresentation: [String: AnyObject] = [
            "uuid": value.uuid,
            "species": value.species,
            "height": value.height,
            "longitude": value.longitude,
            "latitude": value.latitude
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dictionaryRepresentation, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: [])

        guard let
            uuid = json["uuid"] as? String,
            species = json["species"] as? String,
            height = json["height"] as? Int,
            longitude = json["longitude"] as? Double,
            latitude = json["latitude"] as? Double
            else {
                return nil
        }
        return Tree(uuid: uuid, species: species, height: height, longitude: longitude, latitude: latitude)
    }

    func setUp<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
        try transaction.registerCollection(self)
    }

    struct IndexedProperties: Turf.IndexedProperties {

        let species = IndexedProperty<IndexedTreesCollection, String>(name: "species") { tree -> String in
            return tree.species
        }

        let longitude = IndexedProperty<IndexedTreesCollection, Double>(name: "longitude") { tree -> Double in
            return tree.longitude
        }

        let latitude = IndexedProperty<IndexedTreesCollection, Double>(name: "latitude") { tree -> Double in
            return tree.latitude
        }

        var allProperties: [IndexedPropertyFromCollection<IndexedTreesCollection>] {
            return [
                species.lift(),
                longitude.lift(),
                latitude.lift()
            ]
        }
    }
}
