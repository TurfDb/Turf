import Turf

final class Collections: CollectionsContainer {
    let cars = CarsCollection()
    let wheels = WheelsCollection()

//    let unidexedTrees = UnindexedTreesCollection()
    let indexedTrees = IndexedTreesCollection()

    func setUpCollections(transaction transaction: ReadWriteTransaction) throws {
        try cars.setUp(transaction)
        try wheels.setUp(transaction)
        try indexedTrees.setUp(transaction)
    }
}
