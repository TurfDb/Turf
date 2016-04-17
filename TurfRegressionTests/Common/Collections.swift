import Turf

final class Collections: CollectionsContainer {
    let cars = CarsCollection()
    let wheels = WheelsCollection()
    let indexedTrees = IndexedTreesCollection()

    func setUpCollections(using transaction: ReadWriteTransaction<Collections>) throws {
        try cars.setUp(using: transaction)
        try wheels.setUp(using: transaction)
        try indexedTrees.setUp(using: transaction)
    }
}
