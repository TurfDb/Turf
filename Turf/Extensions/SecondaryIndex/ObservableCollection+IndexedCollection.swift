//
extension ObservableCollection where TCollection: IndexedCollection {

    //TODO Threading

    // MARK: Public methods

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter clause: Secondary indexed query to execute on collection change.
     - parameter thread: Thread to execute the prefilter and potential query on.
     - parameter prefilterChangeSet: Executed before querying the collection to determine if the query is required.
     */
    public func values(matching clause: WhereClause, prefilter: (changeSet: ChangeSet<String>, previousValues: [TCollection.Value]) -> Bool) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        var previous: [TCollection.Value] = []

        return self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet: changeSet, previousValues: previous)
            }.map { (collection, changeSet)  in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return TransactionalValue(transaction: collection.readTransaction, value: newValues)
            }
    }

    //TODO PreparedValuesWhereQuery - could it conform to a protocol to make these generic or would that make the signature unwieldy and slow

    public func values(matching clause: WhereClause) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { (collection, changeSet)  in
            let newValues = collection.findValuesWhere(clause)
            return TransactionalValue(transaction: collection.readTransaction, value: newValues)
        }
    }

    public func indexableValues(matching clause: WhereClause) -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { return $0.0.findValuesWhere(clause) })
    }

    public func indexableValues(matching clause: WhereClause, prefilter: (changeSet: ChangeSet<String>, previousValues: [TCollection.Value]) -> Bool) -> IndexableObservable<[TCollection.Value]> {
        var previous: [TCollection.Value] = []

        let observable = self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet: changeSet, previousValues: previous)
            }.map { (collection, changeSet) -> [TCollection.Value] in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return newValues
            }
        return IndexableObservable(observable: observable)
    }

    // MARK: Prepared query


    // MARK: Raw SQL query

}
