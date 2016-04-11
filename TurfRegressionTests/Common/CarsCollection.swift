import Turf

/// CarsCollection is a very basic collection with no extensions and a simple model
class CarsCollection: Collection {
    typealias Value = CarModel

    let name = "Cars"
    let schemaVersion = UInt64(1)
    let valueCacheSize: Int? = nil

    func setUp<DatabaseCollections: CollectionsContainer>(using transaction: ReadWriteTransaction<DatabaseCollections>) throws {
        try transaction.registerCollection(self)
    }

    func serializeValue(value: Value) -> NSData {
        let dict: [String: AnyObject] = [
            "uuid": value.uuid,
            "manufacturer": value.manufacturer,
            "name": value.name,
            "doors": value.doors
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let dict = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        guard let
            uuid = dict["uuid"] as? String,
            manufacturer = dict["manufacturer"] as? String,
            name = dict["name"] as? String,
            doors = dict["doors"] as? Int else {
            return nil
        }
        return CarModel(uuid: uuid, manufacturer: manufacturer, name: name, doors: doors)
    }
}
