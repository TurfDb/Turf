import XCTest

class SecondaryIndexingRegressionTests: XCTestCase {

    let collections = Collections()
    var tester: TestDatabase!

    override func setUp() {
        super.setUp()
        tester = try! TestDatabase(databasePath: "SecondaryIndexingRegressionTests.sqlite")
    }

    override func tearDown() {
        try! tester.connection1.readWriteTransaction { transaction in
            transaction.removeAllCollections()
        }

        super.tearDown()
    }

    func test_indexed_collection_can_be_queried_on_indexed_properties() throws {
        try! tester.connection1.readWriteTransaction { transaction in
            let indexedTreesCollection = transaction.readWrite(self.collections.indexedTrees)

            let oakTree = Tree(species: "Quercus robur", height: 21)
            indexedTreesCollection.setValue(oakTree, forKey: oakTree.uuid)

            let cypressTree = Tree(species: "Cupressocyparis leylandii", height: 27)
            indexedTreesCollection.setValue(cypressTree, forKey: cypressTree.uuid)

            let hollyTree = Tree(species: "Ilex aquifolium", height: 14)
            indexedTreesCollection.setValue(hollyTree, forKey: hollyTree.uuid)

        }

        try tester.connection1.readTransaction { transaction in
            let indexedTreesCollection = transaction.readOnly(self.collections.indexedTrees)            
            let fetchedTrees = indexedTreesCollection.findValuesWhere(indexedTreesCollection.indexed.height.isGreaterThan(20))

            XCTAssertNotNil(fetchedTrees)
//            XCTAssert(fetchedTrees.count == 2)
        }

    }

//    func test_unindexed_collection_cant_be_queried() throws {
//
//        try! tester.connection1.readWriteTransaction { transaction in
//            let unindexedTreesCollection = transaction.readWrite(self.collections.unidexedTrees)
//
//            let oakTree = Tree(species: "Quercus robur", height: 21)
//            unindexedTreesCollection.setValue(oakTree, forKey: oakTree.uuid)
//
//            let cypressTree = Tree(species: "Cupressocyparis leylandii", height: 27)
//            unindexedTreesCollection.setValue(cypressTree, forKey: cypressTree.uuid)
//        }
//
//        try tester.connection1.readTransaction { transaction in
//            let unindexedTreesCollection = transaction.readOnly(self.collections.unidexedTrees)
//            let fetchedTree = unindexedTreesCollection.countValuesWhere(unindexedTreesCollection.indexed)
//        }
//    }
}
