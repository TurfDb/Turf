//import Turf
//
//final class ProductsCollection: SecondaryIndexedTypedCollection {
//    typealias Value = ModelClassA
//    typealias MetadataType = Void
//
//    // MARK: Properties
//
//    let name = "Products"
//    let schemaVersion = UInt(1)
//    let properties = Properties()
//    let index: CollectionSecondaryIndex<ProductsCollection>
//
//    let valueSerializer: (Value -> NSData)    = ProductsCollection.serializer
//    let valueDeserializer: (NSData -> Value?) = ProductsCollection.deserializer
//    let metadataSerializer: (Void -> NSData)      = NoSerializer
//    let metadataDeserializer: (NSData -> Void?)   = NoDeserializer
//
//    init() {
//        var indexedProperties = SecondaryIndexedProperties<ProductsCollection>()
//        indexedProperties.addProperty(properties.name)
//        indexedProperties.addProperty(properties.type)
//
//        index = CollectionSecondaryIndex(collectionName: name, attributes: indexedProperties)
//    }
//
//    // MARK: Setup
//
//    func setUp(transaction: ReadWriteTransaction) throws {
//        try transaction.registerCollection(self)
//    }
//
//    // MARK: Private methods
//
//    private class func serializer(value: ModelClassA) -> NSData {
//        return NSData()
//    }
//
//    private class func deserializer(data: NSData) -> ModelClassA? {
//        return nil
//    }
//
//    // MARK: Secondary indexed properties
//
//    struct Properties: CollectionProperties {
//        let name = SecondaryIndexedProperty<ProductsCollection, String>(name: "name") { return $0.name }
//        let type = SecondaryIndexedProperty<ProductsCollection, Int64>(name: "type") { return $0.var2 }
//    }
//}