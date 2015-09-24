//import XCTest
//@testable import Turf
//
//class TurfTests: XCTestCase {
//    
//    override func setUp() {
//        super.setUp()
//
//        let db = try! Database(path: "/Users/jordanhamill/test.sqlite", collections: Collections.self)!
//        let connection = try! db.newConnection()!
//
//        print(connection.databaseAdapter.collectionNames())
//
////        let observingConnection = db.newObservingConnection(shouldAdvanceWhenDatabaseChanges: true)
////
////        let latestCurrentProduct = observingConnection
////            .observeCollection(Collections.Products)
////            .filterWhereValuesMatch(Collections.Products.properties.type.equals(13))
////            .first
////
////
////        let latestLineItems = latestCurrentProduct.onNext { latestProduct, transaction in
////            let collection = transaction.readOnly(Collections.LineItems)
////            return collection.findWhere(collection.properties.productUuid.equals(latestProduct.value.uuid))
////        }
////
////        latestCurrentProduct.onNext(.MainThread) {
////            refreshUI()
////        }
//
////        let latestCurrentProduct = db
////            .observeCollection(Collections.Products)
////            .onConnection(connection)
////            .advanceWhenDatabaseChanges(true)
//////            .advanceWhen { return true }
//////            .advanceManually()
////            .filterWhereValuesMatch(Collections.Products.properties.type.equals(12))// <- Does a SQL query on that snapshot
//////            .filterWhereValueMatches(Collections.Products.properties.name.equals("current")
//////            .filterValues { $0.uuid == currentProduct }
////            .map { return $0.value }
////            .first
////
////        let latestCurrentProductsLineItems = latestCurrentProduct.onNext {
////            let lineItems = transaction.readOnly(.LineItems)
////            return lineItems.where(lineItems.properties.uuid.isIn($0.value.lineItemUuids))
////        }
////
////        latestCurrentProduct.onNext {
////            refreshUI()
////        }
//
//        let token = db.observeCollection(Collections.Products) { (valueChanges, metadataChanges, removedCollection) in
//            for change in valueChanges {
//                print(change)
//            }
//
//            for change in metadataChanges {
//                print(change)
//            }
//            
//            if removedCollection {
//                print("Removed collection")
//            }
//        }
//
//        connection.readWriteTransaction { transaction in
//            let collection = transaction.readWrite(Collections.Products)
//            collection.removeAllValues()
//        }
//
//
//        connection.readWriteTransaction { transaction in
//            let collection = transaction.readWrite(Collections.Products)
//            collection.setValue(ModelClassA(), forKey: "1234")
//            collection.setValue(ModelClassA(), forKey: "1235")
//            collection.setValue(ModelClassA(), forKey: "1234")
//        }
//
//        db.stopObservingToken(token, fromCollection: Collections.Products)
//
//        connection.readTransaction { transaction in
//            let collection = transaction.readOnly(Collections.Products)
//            print(collection.firstValueWhere("1=1"))
////            collection.findValueWhere(collection.properties.name.equals(""))
////            collection.index.findValueWhere(collection.properties.name).equals("")
//        }
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//    
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//}
