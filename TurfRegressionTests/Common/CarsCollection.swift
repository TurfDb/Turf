import Turf

/// CarsCollection is a very basic collection with no extensions and a simple model
class CarsCollection: TurfCollection {
    typealias Value = CarModel

    let name = "Cars"
    let schemaVersion = UInt64(1)
    let valueCacheSize: Int? = nil

    func setUp<DatabaseCollections: CollectionsContainer>(using transaction: ReadWriteTransaction<DatabaseCollections>) throws {
        try transaction.registerCollection(self)
    }

    func serializeValue(_ value: Value) -> Data {
        let dict: [String: Any] = [
            "uuid": value.uuid,
            "manufacturer": value.manufacturer,
            "name": value.name,
            "doors": value.doors
        ]

        return try! JSONSerialization.data(withJSONObject: dict, options: [])
    }

    func deserializeValue(_ data: Data) -> Value? {
        let dict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        guard let
            uuid = dict["uuid"] as? String,
            let manufacturer = dict["manufacturer"] as? String,
            let name = dict["name"] as? String,
            let doors = dict["doors"] as? Int else {
            return nil
        }
        return CarModel(uuid: uuid, manufacturer: manufacturer, name: name, doors: doors)
    }
}
