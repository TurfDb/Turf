import Foundation

final class UnindexedTreesCollection: Collection {

    typealias Value = Tree

    let name = "UnindexedTrees"

    let schemaVersion = UInt64(1)

    let valueCacheSize: Int? = nil

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
}
