import XCTest

class BasicRegressionTests: XCTestCase {
    var tester: TestDatabase!

    override func setUp() {
        super.setUp()
        tester = try! TestDatabase(databasePath: "BasicRegressionTests.sqlite")
        try! tester.connection1.readWriteTransaction { transaction in
            transaction.removeAllCollections()
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Basic struct persistence
    
    func test_SingleConnection_StructWriteThenRead_FromReadWriteCollection() throws {
        let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            collection.setValue(expectedCar, forKey: expectedCar.uuid)
        }

        var fetchedCar: CarModel?

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            fetchedCar = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedCar)
        XCTAssert(fetchedCar?.uuid == "test_1")
        XCTAssert(fetchedCar?.manufacturer == "McLaren")
        XCTAssert(fetchedCar?.name == "P1")
        XCTAssert(fetchedCar?.doors == 2)
    }

    func test_SingleConnection_StructWriteThenRead_FromReadOnlyCollection() throws {
        let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            collection.setValue(expectedCar, forKey: expectedCar.uuid)
        }

        var fetchedCar: CarModel?

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readOnly(self.tester.collections.cars)
            fetchedCar = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedCar)
        XCTAssert(fetchedCar?.uuid == "test_1")
        XCTAssert(fetchedCar?.manufacturer == "McLaren")
        XCTAssert(fetchedCar?.name == "P1")
        XCTAssert(fetchedCar?.doors == 2)
    }

    func test_TwoConnections_StructWriteThenRead_FromReadWriteCollection() throws {
        let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            collection.setValue(expectedCar, forKey: expectedCar.uuid)
        }

        var fetchedCar: CarModel?

        try tester.connection2.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            fetchedCar = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedCar)
        XCTAssert(fetchedCar?.uuid == "test_1")
        XCTAssert(fetchedCar?.manufacturer == "McLaren")
        XCTAssert(fetchedCar?.name == "P1")
        XCTAssert(fetchedCar?.doors == 2)
    }

    func test_TwoConnections_StructWriteThenRead_FromReadOnlyCollection() throws {
        let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.cars)
            collection.setValue(expectedCar, forKey: expectedCar.uuid)
        }

        var fetchedCar: CarModel?

        try tester.connection2.readWriteTransaction { transaction in
            let collection = transaction.readOnly(self.tester.collections.cars)
            fetchedCar = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedCar)
        XCTAssert(fetchedCar?.uuid == "test_1")
        XCTAssert(fetchedCar?.manufacturer == "McLaren")
        XCTAssert(fetchedCar?.name == "P1")
        XCTAssert(fetchedCar?.doors == 2)
    }

    // MARK: Basic class persistence

    func test_SingleConnection_ClassWriteThenRead_FromReadWriteCollection() throws {
        let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            collection.setValue(expectedWheel, forKey: expectedWheel.uuid)
        }

        var fetchedWheel: WheelModel?

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            fetchedWheel = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedWheel)
        XCTAssert(fetchedWheel?.uuid == "test_1")
        XCTAssert(fetchedWheel?.manufacturer == "Pirelli")
        XCTAssert(fetchedWheel?.size == 18.0)
    }

    func test_SingleConnection_ClassWriteThenRead_FromReadOnlyCollection() throws {
        let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            collection.setValue(expectedWheel, forKey: expectedWheel.uuid)
        }

        var fetchedWheel: WheelModel?

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readOnly(self.tester.collections.wheels)
            fetchedWheel = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedWheel)
        XCTAssert(fetchedWheel?.uuid == "test_1")
        XCTAssert(fetchedWheel?.manufacturer == "Pirelli")
        XCTAssert(fetchedWheel?.size == 18.0)
    }

    func test_TwoConnections_ClassWriteThenRead_FromReadWriteCollection() throws {
        let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            collection.setValue(expectedWheel, forKey: expectedWheel.uuid)
        }

        var fetchedWheel: WheelModel?

        try tester.connection2.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            fetchedWheel = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedWheel)
        XCTAssert(fetchedWheel?.uuid == "test_1")
        XCTAssert(fetchedWheel?.manufacturer == "Pirelli")
        XCTAssert(fetchedWheel?.size == 18.0)
    }

    func test_TwoConnections_ClassWriteThenRead_FromReadOnlyCollection() throws {
        let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

        try tester.connection1.readWriteTransaction { transaction in
            let collection = transaction.readWrite(self.tester.collections.wheels)
            collection.setValue(expectedWheel, forKey: expectedWheel.uuid)
        }

        var fetchedWheel: WheelModel?

        try tester.connection2.readWriteTransaction { transaction in
            let collection = transaction.readOnly(self.tester.collections.wheels)
            fetchedWheel = collection.valueForKey("test_1")
        }

        XCTAssertNotNil(fetchedWheel)
        XCTAssert(fetchedWheel?.uuid == "test_1")
        XCTAssert(fetchedWheel?.manufacturer == "Pirelli")
        XCTAssert(fetchedWheel?.size == 18.0)
    }
}
