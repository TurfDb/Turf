import Foundation
import Turf

class LineItemsCollection: Collection {
    typealias Value = LineItem

    let name = "LineItems"
    let schemaVersion = UInt(1)
    let valueCacheSize: Int? = 50

    func setUp(transaction: ReadWriteTransaction) {
        
    }

    func serializeValue(value: Value) -> NSData {
        return NSData()
    }

    func deserializeValue(data: NSData) -> Value? {
        return nil
    }
}
