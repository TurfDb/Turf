import XCTest
import Turf

class BasicSample: XCTestCase {
    var collections: Collections!
    override func setUp() {
        super.setUp()

        collections = Collections()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        let expectation = expectationWithDescription("just waiting to test stuff")

        let db = try! Database(path: "/Users/jordanhamill/basic2.sqlite", collections: collections)
        let connection = try! db.newConnection()
        let connection2 = try! db.newConnection()

        NSNotificationCenter.defaultCenter().addObserverForName(Database.CollectionChangedNotification, object: collections.Checks, queue: nil) { notification in
            let changeSet = notification.userInfo?[Database.CollectionChangedNotificationChangeSetKey] as? ChangeSet<String>
            print(changeSet?.changes)
        }

        connection.readWriteTransaction( { transaction in
            print("connection 1 write 1")
            let checksCollection = transaction.readWrite(self.collections.Checks)
            checksCollection.setValue(Check(uuid: "A", name: "A", isOpen: true, lineItemUuids: []), forKey: "1234")
            print(checksCollection.valueForKey("1234")?.uuid)
        }) {
            print("connection 1 write 1 done")
        }

        connection.readWriteTransaction( { transaction in
            print("connection 1 write 2")
            let checksCollection = transaction.readWrite(self.collections.Checks)

            print(checksCollection.valueForKey("1234")?.uuid)

            checksCollection.setValue(Check(uuid: "AB", name: "AB", isOpen: true, lineItemUuids: []), forKey: "1234")
            checksCollection.setValue(Check(uuid: "ABC", name: "ABC", isOpen: true, lineItemUuids: []), forKey: "1234")

            print(checksCollection.valueForKey("1234")?.uuid)
        }) {
            print("connection 1 write 2 done")
        }

//        connection.readWriteTransaction( { transaction in
//            print("connection 1 write 3")
//            let checksCollection = transaction.readWrite(self.collections.Checks)
//
//            print(checksCollection.valueForKey("1234")?.uuid)
//
//            checksCollection.setValue(Check(uuid: "ABCD", name: "ABCD", isOpen: true, lineItemUuids: []), forKey: "1234")
//
//            print(checksCollection.valueForKey("1234")?.uuid)
//        }) {
//            print("connection 1 write 3 done")
//        }

//
        connection2.readWriteTransaction( { transaction in
            print("connection 2 write 1")

            let checksCollection = transaction.readWrite(self.collections.Checks)
            print(checksCollection.valueForKey("1234"))
            checksCollection.setValue(Check(uuid: "ZEG", name: "AB", isOpen: true, lineItemUuids: []), forKey: "1234")
            print(checksCollection.valueForKey("1234"))
//
        }) {
            print("connection 2 write 1 done")
        }
//
//        connection2.readWriteTransaction( { transaction in
//            print("connection 2 write 2")
//        }) {
//            print("connection 2 write 2 done")
//        }
////
        connection.readWriteTransaction( { transaction in
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
