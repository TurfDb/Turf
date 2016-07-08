import Quick
import Nimble
import Turf

class ObservablesRegressionTests: QuickSpec {
    override func spec() {
        describe("Observables regression tests") {
            var tester: TestDatabase!
            beforeEach {
                tester = try! TestDatabase(databasePath: "ObservableRegressionTests.sqlite")
                try! tester.connection1.readWriteTransaction{ transaction, collections in
                    transaction.readWrite(collections.cars).removeAllValues()
                    transaction.readWrite(collections.wheels).removeAllValues()
                }
            }

            context("when observing the cars collection") {
                var observableCarsCollection: ObservableCollection<CarsCollection, Collections>!
                beforeEach {
                    observableCarsCollection = tester.observingConnection.observeCollection(tester.collections.cars)
                }

                context("and a value is written to the wheels collection") {
                    it("does not call didChange with any changes") {

                        var didChangeCalled = false
                        var didChangeCalledWithChanges = true
                        let disposable = observableCarsCollection.subscribeNext { carsCollection, changes in
                            didChangeCalled = true
                            didChangeCalledWithChanges = changes.changes.count > 0 || changes.allValuesRemoved
                        }

                        try! tester.connection1.readWriteTransaction { transaction, collections in
                            let wheel = WheelModel(uuid: "test_1", manufacturer: "Pirelli", size: 18.0)
                            transaction.readWrite(collections.wheels)
                                .setValue(wheel, forKey: wheel.uuid)
                        }

                        expect(didChangeCalled) == true
                        expect(didChangeCalledWithChanges) == false
                        disposable.dispose()
                    }
                }

                context("and a value is written to the cars collection") {
                    it("calls didChange with only an insert for test_1") {

                        var changeSet: ChangeSet<String>?
                        let disposable = observableCarsCollection.subscribeNext { carsCollection, changes in
                            changeSet = changes
                        }

                        try! tester.connection1.readWriteTransaction { transaction, collections in
                            let car = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)
                            transaction.readWrite(collections.cars)
                                .setValue(car, forKey: car.uuid)
                        }

                        expect(changeSet?.hasChangeForKey("test_1")) == true
                        expect(changeSet?.changes.count) == 1
                        expect(changeSet?.allValuesRemoved) == false
                        disposable.dispose()

                        switch changeSet!.changes.first! {
                        case .Insert(let key):
                            if key != "test_1" { fail() }
                        default: fail()
                        }
                    }

                    context("and the value is updated") {
                        beforeEach {
                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let car = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)
                                transaction.readWrite(collections.cars)
                                    .setValue(car, forKey: car.uuid)
                            }
                        }

                        it("calls didChange with only an update for test_1") {

                            var changeSet: ChangeSet<String>?
                            let disposable = observableCarsCollection.subscribeNext { carsCollection, changes in
                                changeSet = changes
                            }

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let car = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)
                                transaction.readWrite(collections.cars)
                                    .setValue(car, forKey: car.uuid)
                            }

                            expect(changeSet?.hasChangeForKey("test_1")) == true
                            expect(changeSet?.changes.count) == 1
                            expect(changeSet?.allValuesRemoved) == false
                            disposable.dispose()

                            switch changeSet!.changes.first! {
                            case .Update(let key):
                                if key != "test_1" { fail() }
                            default: fail()
                            }
                        }
                    }

                    context("and the value is removed") {
                        beforeEach {
                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let car = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)
                                transaction.readWrite(collections.cars)
                                    .setValue(car, forKey: car.uuid)
                            }
                        }

                        it("calls didChange with only a remove for test_1") {

                            var changeSet: ChangeSet<String>?
                            let disposable = observableCarsCollection.subscribeNext { carsCollection, changes in
                                changeSet = changes
                            }

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                transaction.readWrite(collections.cars).removeValuesWithKeys(["test_1"])
                            }

                            expect(changeSet?.hasChangeForKey("test_1")) == true
                            expect(changeSet?.changes.count) == 1
                            expect(changeSet?.allValuesRemoved) == false
                            disposable.dispose()

                            switch changeSet!.changes.first! {
                            case .Remove(let key):
                                if key != "test_1" { fail() }
                            default: fail()
                            }
                        }
                    }

                    context("and all values are removed from cars") {
                        beforeEach {
                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                let car = CarModel(uuid: "test_1", manufacturer: "McLaren", name: "P1", doors: 2)
                                transaction.readWrite(collections.cars)
                                    .setValue(car, forKey: car.uuid)
                            }
                        }

                        it("calls didChange with only allValuesRemoved set") {

                            var changeSet: ChangeSet<String>?
                            let disposable = observableCarsCollection.subscribeNext { carsCollection, changes in
                                changeSet = changes
                            }

                            try! tester.connection1.readWriteTransaction { transaction, collections in
                                transaction.readWrite(collections.cars).removeAllValues()
                            }

                            expect(changeSet?.hasChangeForKey("test_1")) == true
                            expect(changeSet?.changes.count) == 0
                            expect(changeSet?.allValuesRemoved) == true
                            disposable.dispose()
                        }
                    }
                }
            }
        }
    }
}
