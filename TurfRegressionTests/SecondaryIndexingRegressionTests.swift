import XCTest

final class Collections: CollectionsContainer {
    let unindexedTrees = UnindexedTreesCollection()

    func setUpCollections<Collections: CollectionsContainer>(using transaction: ReadWriteTransaction<Collections>) throws {
        try unindexedTrees.setUp(using: transaction)
    }
}

class SecondaryIndexingRegressionTests: XCTestCase {

    let collections = Collections()
    var tester: Database!

    override func setUp() {
        super.setUp()
        tester = try! Database(databasePath: "SecondaryIndexingRegressionTests.sqlite", collections: collections)
    }

    override func tearDown() {
        try! tester.readWriteTransaction { transaction in
            transaction.removeAllCollections()
        }

        super.tearDown()
    }

    func test_unindexed_collection_cant_be_queried() throws {


        try! tester.connection1.readWriteTransaction { transaction in

        }
    }
}
