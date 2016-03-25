import Turf

class Collections: CollectionsContainer {
    let Checks = ChecksCollection()
    let LineItems = LineItemsCollection()

    func setUpCollections(transaction transaction: ReadWriteTransaction) throws {
        try Checks.setUp(transaction)
        try LineItems.setUp(transaction)
    }
}
