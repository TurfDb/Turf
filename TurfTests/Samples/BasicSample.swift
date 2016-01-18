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
            print("connection 1 write 1")
            changeSetToken = transaction.readOnly(self.collections.LineItems)
                .registerPermamentChangeSetObserver { changeSet in
                    print(changeSet.changes)
                }
        }) {
            print("connection 1 write 1 done")
        }

        connection.readWriteTransaction( { transaction in
            print("connection 1 write 2")
            let checksCollection = transaction.readWrite(self.collections.Checks)

            print(checksCollection.valueForKey("1234"))

            checksCollection.setValue(Check(uuid: "1234", name: "A", isOpen: true, lineItemUuids: []), forKey: "1234")
            print(checksCollection.valueForKey("1234"))
        }) {
            print("connection 1 write 2 done")
        }

        connection2.readWriteTransaction( { transaction in
            print("connection 2 write 1")

            let checksCollection = transaction.readWrite(self.collections.Checks)
            print(checksCollection.valueForKey("1234"))
            checksCollection.setValue(Check(uuid: "1234", name: "AB", isOpen: true, lineItemUuids: []), forKey: "1234")

        }) {
            print("connection 2 write 1 done")
        }

        connection2.readWriteTransaction( { transaction in
            print("connection 2 write 2")
        }) {
            print("connection 2 write 2 done")
            expectation.fulfill()
        }


        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
