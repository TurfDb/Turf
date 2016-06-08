import Quick
import Nimble

import Turf

class SecondaryIndexingRegressionTests: QuickSpec {

    override func spec() {

        describe("Secondary Index regression tests") {
            var tester: TestDatabase!

            context("with a database with a collection that is indexed") {

                beforeEach {
                    tester = try! TestDatabase(databasePath: "SecondaryIndexRegressionTests.sqlite")

                    try! tester.connection1.readWriteTransaction{ transaction, collections in

                        transaction.readWrite(collections.indexedTrees).removeAllValues()
                    }
                }

                context("when the database has a number of records") {

                    beforeEach {
                        try! tester.connection1.readWriteTransaction { transaction, collections in

                            let treesCollections = transaction.readWrite(collections.indexedTrees)

                            let oakTree1 = Tree(type: "Oak", species: "Quercus robur", height: 21, age: .Young)

                            let oakTree2 = Tree(type: "Oak", species: "Quercus robur", height: 27, age: .Mature)

                            let cypressTree1 = Tree(type: "Cypress", species: "Cupressocyparis leylandii", height: 23, age: .FullyMature)

                            let cypressTree2 = Tree(type: "Cypress", species: "Cupressocyparis leylandii", height: 19, age: .Mature)

                            let beechTree1 = Tree(type: "Beech", species: "Ilex aquifolium", height: 14, age: .Mature)

                            let beechTree2 = Tree(type: "Beech", species: "Ilex aquifolium", height: 15, age: .Mature)

                            let beechTree3 = Tree(type: "Beech", species: "Ilex aquifolium", height: 18, age: .FullyMature)

                            treesCollections.setValue(oakTree1, forKey: oakTree1.uuid)
                            treesCollections.setValue(oakTree2, forKey: oakTree2.uuid)
                            treesCollections.setValue(cypressTree1, forKey: cypressTree1.uuid)
                            treesCollections.setValue(cypressTree2, forKey: cypressTree2.uuid)
                            treesCollections.setValue(beechTree1, forKey: beechTree1.uuid)
                            treesCollections.setValue(beechTree2, forKey: beechTree2.uuid)
                            treesCollections.setValue(beechTree3, forKey: beechTree3.uuid)
                        }
                    }

                    it("allows us to search on the IndexedTreeCollections 'type' property") {
                        var oakTrees: [Tree] = []

                        try! tester.connection1.readTransaction { transaction, collections in

                            let treesCollection = transaction.readOnly(collections.indexedTrees)

                            oakTrees = treesCollection.findValuesWhere(treesCollection.indexed.type.equals("Oak"))
                        }

                        expect(oakTrees.count) == 2
                    }

                    it("allows us to search on the IndexedTreeCollections 'species' property") {
                        var beechTrees: [Tree] = []

                        try! tester.connection1.readTransaction { transaction, collections in

                            let treesCollection = transaction.readOnly(collections.indexedTrees)

                            beechTrees = treesCollection.findValuesWhere(treesCollection.indexed.species.equals("Ilex aquifolium"))
                        }

                        expect(beechTrees.count) == 3
                    }

                    it("allows us to search on the IndexedTreeCollections 'height' property") {
                        var tallTrees: [Tree] = []

                        try! tester.connection1.readTransaction { transaction, collections in

                            let treesCollection = transaction.readOnly(collections.indexedTrees)

                            tallTrees = treesCollection.findValuesWhere(treesCollection.indexed.height.isGreaterThan(20))
                        }

                        expect(tallTrees.count) == 3
                    }

                    it("allows us to search on the IndexedTreeCollections 'age' property") {
                        var oldTrees: [Tree] = []

                        try! tester.connection1.readTransaction { transaction, collections in

                            let treesCollection = transaction.readOnly(collections.indexedTrees)

                            oldTrees = treesCollection.findValuesWhere(treesCollection.indexed.age.isGreaterThanOrEqualTo(TreeAge.Mature.rawValue))
                        }

                        expect(oldTrees.count) == 6
                    }


                    it("") {
                        let cl = tester.collections.indexedTrees.indexed.age.equals(1)
                        let coll = tester.observingConnection.observe(collection: tester.collections.indexedTrees)

                        let _ = coll.indexableValues(matching: cl).subscribeNext { trees in
                            print(trees.first)
                        }

                        //TODO Figure out hot-ness / shareable-ness (shouldn't be shared
                        let firstTree = coll.indexableValues(matching: cl)[observableIndex: 0]
                        let _ = firstTree.subscribeNext { tree in
                            print(tree?.age)
                        }
                    }

                }
            }
        }
    }
}
