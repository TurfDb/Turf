import Turf

final class Collections: CollectionsContainer {
    let cars = CarsCollection()
    let wheels = WheelsCollection()

    func setUpCollections(using transaction: ReadWriteTransaction<Collections>) throws {
        try cars.setUp(using: transaction)
        try wheels.setUp(using: transaction)
    }
}
