import Foundation
import Turf

class LineItemsCollection: Collection {
    typealias Value = LineItem

    let name = "LineItems"
    let schemaVersion = UInt64(1)
    let valueCacheSize: Int? = 50

    func setUp(transaction: ReadWriteTransaction) throws {
        try transaction.registerCollection(self)
    }

    func serializeValue(value: Value) -> NSData {
        return NSData()
    }

    func deserializeValue(data: NSData) -> Value? {
        return nil
    }
}
