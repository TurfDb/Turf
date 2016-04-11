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

    func serializeValue(value: Value) -> NSData {
        let dict: [String: AnyObject] = [
            "uuid": value.uuid,
            "manufacturer": value.manufacturer,
            "size": value.size
        ]

        return try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }

    func deserializeValue(data: NSData) -> Value? {
        let dict = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        guard let
            uuid = dict["uuid"] as? String,
            manufacturer = dict["manufacturer"] as? String,
            size = dict["size"] as? Double else {
                return nil
        }
        return WheelModel(uuid: uuid, manufacturer: manufacturer, size: size)
    }
}
