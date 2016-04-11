import Turf

final class Collections: CollectionsContainer {
    let cars = CarsCollection()
    let wheels = WheelsCollection()

    func setUpCollections(transaction transaction: ReadWriteTransaction<Collections>) throws {
        try cars.setUp(transaction)
        try wheels.setUp(transaction)
    }
}
