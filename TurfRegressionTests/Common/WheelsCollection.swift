import Turf

/// WheelsCollection is a very basic collection with no extensions and a simple class model
class WheelsCollection: Collection {
    typealias Value = WheelModel

    let name = "Wheels"
    let schemaVersion = UInt64(1)
    let valueCacheSize: Int? = nil

    func setUp<DatabaseCollections: CollectionsContainer>(using transaction: ReadWriteTransaction<DatabaseCollections>) throws {
        try transaction.registerCollection(self)
    }

    func serializeValue(_ value: Value) -> Data {
        let dict: [String: AnyObject] = [
            "uuid": value.uuid,
            "manufacturer": value.manufacturer,
            "size": value.size
        ]

        return try! JSONSerialization.data(withJSONObject: dict, options: [])
    }

    func deserializeValue(_ data: Data) -> Value? {
        let dict = try! JSONSerialization.jsonObject(with: data, options: [])
        guard let
            uuid = dict["uuid"] as? String,
            let manufacturer = dict["manufacturer"] as? String,
            let size = dict["size"] as? Double else {
                return nil
        }
        return WheelModel(uuid: uuid, manufacturer: manufacturer, size: size)
    }
}
