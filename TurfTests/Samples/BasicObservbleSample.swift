import XCTest
import Turf

class BasicObservableSample: XCTestCase {
    var collections: Collections!
    var db: Database!
    override func setUp() {
        super.setUp()

        collections = Collections()
        db = try! Database(path: "/Users/jordanhamill/basic3.sqlite", collections: collections)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        let expectation = expectationWithDescription("just waiting to test stuff")

        func lineItemsForCheck(check: Check, transaction: ReadTransaction) -> [LineItem] {
            let lineItemsCollection = transaction.readOnly(self.collections.LineItems)
            let checksCollection = transaction.readOnly(self.collections.Checks)
            return []
//            return checksCollection
//                .destinationValuesInCollection(
//                    lineItemsCollection,
//                    forRelationship: checksCollection.relationships.lineItems,
//                    fromSource: check)
        }

        func hasChangeForPreviousValue<T>(previousValues: [T], _ changeSet: ChangeSet<String>, key: (T) -> String) -> Bool {
            for previousValue in previousValues
                where changeSet.hasChangeForKey(key(previousValue)) {
                    return true
            }
            return false
        }



        let connection = try! db.newConnection()

        let observingConnection = try! db.newObservingConnection()

        let observableChecksCollection = observingConnection
            .observeCollection(collections.Checks)

        observableChecksCollection.didChange { (checksCollection, changeSet) in
            print("\t\(changeSet)")
            print("\t\(checksCollection!.valueForKey("1234")?.uuid)")
        }


        let currentCheck = observableChecksCollection
            .valuesWhere(collections.Checks.indexed.isOpen.equals(true),
                prefilterChangeSet: {
                    return hasChangeForPreviousValue($0, $1, key: { check in return check.uuid })
                }
            ).first

        let currentLineItems = CollectionTypeObserver<[LineItem]>(initalValue: [])
        currentCheck.didChange { check, transaction in
            guard let check = check else { return }

            let lineItems = lineItemsForCheck(check, transaction: transaction!)
            currentLineItems.setValue(lineItems, fromTransaction: transaction!)
        }

        currentCheck.didChange(.MainThread) { (check, transaction) in
            print("check: \(check)")
        }

        currentLineItems.didChange(.MainThread) { (lineItems, transaction) in
            print("line items: \(lineItems)")
        }

        connection.readWriteTransaction({ transaction in
            let checksCollection = transaction.readWrite(self.collections.Checks)
            checksCollection.removeAllValues()
            let check = Check(uuid: "A", name: "A", isOpen: true, isCurrent: false, lineItemUuids: [])
            checksCollection.setValue(check, forKey: "1234")
        })

        connection.readWriteTransaction({ transaction in
            let checksCollection = transaction.readWrite(self.collections.Checks)

            print(checksCollection.valueForKey("1234")?.uuid)

            let check = Check(uuid: "AB", name: "AB", isOpen: true, isCurrent: false, lineItemUuids: [])
            checksCollection.setValue(check, forKey: "1234")
        })

        connection.readTransaction({ transaction in
            let checksCollection = transaction.readOnly(self.collections.Checks)
            print(checksCollection.valueForKey("1234")?.uuid)
            currentLineItems.disposeBag.dispose(disposeAncestors: true)
            expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(15, handler: nil)
    }
}
