import Turf

class Collections: CollectionsContainer {
    let Checks = ChecksCollection()
    let LineItems = LineItemsCollection()

    func setUpCollections(transaction transaction: ReadWriteTransaction) {
        Checks.setUp(transaction)
        LineItems.setUp(transaction)
    }
}
