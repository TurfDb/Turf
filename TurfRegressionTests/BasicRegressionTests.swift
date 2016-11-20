import Quick
import Nimble

class BasicRegressionTests: QuickSpec {
    override func spec() {
        describe("Basic regression tests") {
            var tester: TestDatabase!
            beforeEach {
                tester = try! TestDatabase(databasePath: "BasicRegressionTests.sqlite")
                try! tester.connection1.readWriteTransaction { transaction, collections in
                    transaction.readWrite(collections.cars).removeAllValues()
                    transaction.readWrite(collections.wheels).removeAllValues()
                }
            }

            // MARK: Struct persistence

            describe("Struct Models") {
                context("with a single database connection") {
                    context("and using only a read-write collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.cars)
                                collection.set(value: expectedCar, forKey: expectedCar.uuid)
                            }

                            var fetchedCar: CarModel?
                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.cars)
                                fetchedCar = collection.value(for: "test_1")
                            }

                            expect(fetchedCar?.uuid) == "test_1"
                            expect(fetchedCar?.manufacturer) == "McLaren"
                            expect(fetchedCar?.name) == "P1"
                            expect(fetchedCar?.doors) == 2
                        }
                    }

                    context("and using a read-write and read-only collection") {
                        context("with a read-write transaction") {
                            it("successfully writes a model and can read it back") {
                                let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                                try! tester.connection1.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readWrite(collections.cars)
                                    collection.set(value: expectedCar, forKey: expectedCar.uuid)
                                }

                                var fetchedCar: CarModel?
                                try! tester.connection1.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readOnly(collections.cars)
                                    fetchedCar = collection.value(for:"test_1")
                                }

                                expect(fetchedCar?.uuid) == "test_1"
                                expect(fetchedCar?.manufacturer) == "McLaren"
                                expect(fetchedCar?.name) == "P1"
                                expect(fetchedCar?.doors) == 2
                            }
                        }

                        context("with a read-write and read-only transaction") {
                            it("successfully writes a model and can read it back") {
                                let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                                try! tester.connection1.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readWrite(collections.cars)
                                    collection.set(value: expectedCar, forKey: expectedCar.uuid)
                                }

                                var fetchedCar: CarModel?
                                try! tester.connection1.readTransaction { transaction, collections in
                                    let collection = transaction.readOnly(collections.cars)
                                    fetchedCar = collection.value(for:"test_1")
                                }

                                expect(fetchedCar?.uuid) == "test_1"
                                expect(fetchedCar?.manufacturer) == "McLaren"
                                expect(fetchedCar?.name) == "P1"
                                expect(fetchedCar?.doors) == 2
                            }
                        }
                    }
                }

                // 2 connections

                context("with 2 database connections") {
                    context("and using a read-write collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.cars)
                                collection.set(value: expectedCar, forKey: expectedCar.uuid)
                            }

                            var fetchedCar: CarModel?
                            try! tester.connection2.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.cars)
                                fetchedCar = collection.value(for:"test_1")
                            }

                            expect(fetchedCar?.uuid) == "test_1"
                            expect(fetchedCar?.manufacturer) == "McLaren"
                            expect(fetchedCar?.name) == "P1"
                            expect(fetchedCar?.doors) == 2
                        }
                    }

                    context("and using a read-write and read-only collection") {
                        context("with a read-write transaction") {
                            it("successfully writes a model and can read it back") {
                                let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                                try! tester.connection1.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readWrite(collections.cars)
                                    collection.set(value: expectedCar, forKey: expectedCar.uuid)
                                }

                                var fetchedCar: CarModel?
                                try! tester.connection2.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readOnly(collections.cars)
                                    fetchedCar = collection.value(for:"test_1")
                                }

                                expect(fetchedCar?.uuid) == "test_1"
                                expect(fetchedCar?.manufacturer) == "McLaren"
                                expect(fetchedCar?.name) == "P1"
                                expect(fetchedCar?.doors) == 2
                            }
                        }

                        context("with a read-write and read-only transaction") {
                            it("successfully writes a model and can read it back") {
                                let expectedCar = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)

                                try! tester.connection1.readWriteTransaction { transaction, collections in
                                    let collection = transaction.readWrite(collections.cars)
                                    collection.set(value: expectedCar, forKey: expectedCar.uuid)
                                }

                                var fetchedCar: CarModel?
                                try! tester.connection2.readTransaction { transaction, collections in
                                    let collection = transaction.readOnly(collections.cars)
                                    fetchedCar = collection.value(for:"test_1")
                                }

                                expect(fetchedCar?.uuid) == "test_1"
                                expect(fetchedCar?.manufacturer) == "McLaren"
                                expect(fetchedCar?.name) == "P1"
                                expect(fetchedCar?.doors) == 2
                            }
                        }
                    }
                }
            }

            // MARK: Class persistence

            describe("Class Models") {
                context("with a single database connection") {
                    context("and using a read-write collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                collection.set(value: expectedWheel, forKey: expectedWheel.uuid)
                            }

                            var fetchedWheel: WheelModel?

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                fetchedWheel = collection.value(for:"test_1")
                            }

                            expect(fetchedWheel?.uuid) == "test_1"
                            expect(fetchedWheel?.manufacturer) == "Pirelli"
                            expect(fetchedWheel?.size) == 18.0
                        }
                    }

                    context("and using a read-write and read-only collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                collection.set(value: expectedWheel, forKey: expectedWheel.uuid)
                            }

                            var fetchedWheel: WheelModel?

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readOnly(collections.wheels)
                                fetchedWheel = collection.value(for:"test_1")
                            }

                            expect(fetchedWheel?.uuid) == "test_1"
                            expect(fetchedWheel?.manufacturer) == "Pirelli"
                            expect(fetchedWheel?.size) == 18.0
                        }
                    }
                }

                // 2 connections

                context("with 2 database connections") {
                    context("and using a read-write collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                collection.set(value: expectedWheel, forKey: expectedWheel.uuid)
                            }

                            var fetchedWheel: WheelModel?

                            try! tester.connection2.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                fetchedWheel = collection.value(for:"test_1")
                            }

                            expect(fetchedWheel?.uuid) == "test_1"
                            expect(fetchedWheel?.manufacturer) == "Pirelli"
                            expect(fetchedWheel?.size) == 18.0
                        }
                    }

                    context("and using a read-write and read-only collection") {

                        it("successfully writes a model and can read it back") {
                            let expectedWheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let collection = transaction.readWrite(collections.wheels)
                                collection.set(value: expectedWheel, forKey: expectedWheel.uuid)
                            }

                            var fetchedWheel: WheelModel?

                            try! tester.connection2.readWriteTransaction { transaction, collections in
                                let collection = transaction.readOnly(collections.wheels)
                                fetchedWheel = collection.value(for:"test_1")
                            }

                            expect(fetchedWheel?.uuid) == "test_1"
                            expect(fetchedWheel?.manufacturer) == "Pirelli"
                            expect(fetchedWheel?.size) == 18.0
                        }
                    }
                }
            }
        }
    }
}
