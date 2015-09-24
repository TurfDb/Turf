# Turf

Really strongly typed document store built upon SQLite.


## Example benchmark

```swift
import Turf

final class ChecksCollection: Collection {
    typealias Value = Check

    let name = "Checks"
    let schemaVersion = UInt(1)
    let valueCacheSize: Int? = 50

    init() { }

    func setUp(transaction: ReadWriteTransaction) {
        transaction.registerCollection(self)
    }

    func serializeValue(value: Value) -> NSData {
        return NSData()//TODO
    }

    func deserializeValue(data: NSData) -> Value? {
        return nil//TODO
    }
}

final class LineItemsCollection: Collection {
    typealias Value = LineItem

    let name = "LineItems"
    let schemaVersion = UInt(1)
    let valueCacheSize: Int? = 50

    func setUp(transaction: ReadWriteTransaction) {
        transaction.registerCollection(self)
    }

    func serializeValue(value: Value) -> NSData {
        return NSData()
    }

    func deserializeValue(data: NSData) -> Value? {
        return nil
    }
}

final class Collections: CollectionsContainer {
    let Checks = ChecksCollection()
    let LineItems = LineItemsCollection()

    func setUpCollections(transaction transaction: ReadWriteTransaction) {
        Checks.setUp(transaction)
        LineItems.setUp(transaction)
    }
}


class TurfTests: XCTestCase {
    var database: Database!
    var connection: Turf.Connection!
    var collections: Collections!

    override func setUp() {
        super.setUp()
        collections = Collections()
        database = try! Database(path: "basic.sqlite", collections: collections)
        connection = try! db.newConnection()

        connection.readWriteTransaction { transaction in
            let checksCollection = transaction.readOnly(collections.Checks)
            let lineItemsCollection = transaction.readWrite(collections.LineItems)

            lineItemsCollection.setValue(LineItem(uuid: "1234", name: "A", price: 10.0), forKey: "1234")
            let check = checksCollection.valueForKey("9876")
    }
}

```
