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

        var changeSetToken: String!

        connection.readWriteTransaction( { transaction in
            print("read transaction 1")
            changeSetToken = transaction.readOnly(self.collections.LineItems)
                .registerPermamentChangeSetObserver { changeSet in
                    print(changeSet.changes)
                }
        }) {
            print("read transaction 1 done")
        }

        connection.readWriteTransaction( { transaction in
            print("writing")
            let checksCollection = transaction.readWrite(self.collections.Checks)
//            let lineItemsCollection = transaction.readWrite(self.collections.LineItems)
//
//            //Non secondary indexed query - todo make the generator deserialization lazy
////            for openCheck in checksCollection.allValues.lazy.filter({ return $0.isOpen }) {
////                print(openCheck.name)
////            }
////
////            for openCheck in checksCollection.findValuesWhere(checksCollection.indexed.isOpen.equals(true)) {
////                print(openCheck.name)
////            }
//
            print(checksCollection.valueForKey("1234"))

            checksCollection.setValue(Check(uuid: "1234", name: "A", isOpen: true, lineItemUuids: []), forKey: "1234")
            print(checksCollection.valueForKey("1234"))
//            lineItemsCollection.setValue(LineItem(uuid: "1", name: "A", price: 1.0), forKey: "1234")
//
////            if let check = checksCollection.valueForKey("1234") {
////                checksCollection.setDestinationValuesInCollection(
////                    lineItemsCollection,
////                    forRelationship: checksCollection.relationships.lineItems,
////                    fromSource: check)
////
////                let _ = checksCollection.destinationValuesInCollection(
////                    lineItemsCollection,
////                    forRelationship: checksCollection.relationships.lineItems,
////                    fromSource: check)
////
////                let _ = checksCollection.destinationKeysForRelationship(
////                    checksCollection.relationships.lineItems,
////                    fromSource: check)
////
////            }
//
////            dispatch_after(8, dispatch_get_main_queue(), { () -> Void in
////                expectation.fulfill()
////            })
        }) {
            print("written")
        }

        connection2.readWriteTransaction( { transaction in
            print("unregistering")

            let checksCollection = transaction.readWrite(self.collections.Checks)
            print(checksCollection.valueForKey("1234"))
            checksCollection.setValue(Check(uuid: "1234", name: "AB", isOpen: true, lineItemUuids: []), forKey: "1234")

//            transaction.readOnly(self.collections.LineItems)
//                .unregisterPermamentChangeSetObserver(changeSetToken)
        }) {
            print("unregistered")
//            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
