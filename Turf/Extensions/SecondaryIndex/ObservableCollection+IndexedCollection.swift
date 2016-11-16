//
extension ObservableCollection where TCollection: IndexedCollection {

    //TODO Threading

    // MARK: Public methods

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     */
    public func values(matching clause: WhereClause) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { (collection, changeSet)  in
            let newValues = collection.findValuesWhere(clause)
            return TransactionalValue(transaction: collection.readTransaction, value: newValues)
        }
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func values(matching clause: WhereClause, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        var previous: [TCollection.Value] = []

        return self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet)  in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return TransactionalValue(transaction: collection.readTransaction, value: newValues)
            }
    }

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     */
    public func indexableValues(matching clause: WhereClause) -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { return $0.0.findValuesWhere(clause) })
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func indexableValues(matching clause: WhereClause, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> IndexableObservable<[TCollection.Value]> {
        var previous: [TCollection.Value] = []

        let observable = self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet) -> [TCollection.Value] in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return newValues
            }
        return IndexableObservable(observable: observable)
    }

    // MARK: Prepared query

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     */
    public func values(matching clause: PreparedValuesWhereQuery<Collections>) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { (collection, changeSet)  in
            let newValues = collection.findValuesWhere(clause)
            return TransactionalValue(transaction: collection.readTransaction, value: newValues)
        }
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func values(matching clause: PreparedValuesWhereQuery<Collections>, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        var previous: [TCollection.Value] = []

        return self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet)  in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return TransactionalValue(transaction: collection.readTransaction, value: newValues)
            }
    }

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     */
    public func indexableValues(matching clause: PreparedValuesWhereQuery<Collections>) -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { return $0.0.findValuesWhere(clause) })
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matching: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func indexableValues(matching clause: PreparedValuesWhereQuery<Collections>, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> IndexableObservable<[TCollection.Value]> {
        var previous: [TCollection.Value] = []

        let observable = self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet) -> [TCollection.Value] in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return newValues
            }
        return IndexableObservable(observable: observable)
    }

    // MARK: Raw SQL query

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matchingRawSql: Secondary indexed query to execute on collection change.
     */
    public func values(matchingRawSql clause: String) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { (collection, changeSet)  in
            let newValues = collection.findValuesWhere(clause)
            return TransactionalValue(transaction: collection.readTransaction, value: newValues)
        }
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matchingRawSql: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func values(matchingRawSql clause: String, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        var previous: [TCollection.Value] = []

        return self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet)  in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return TransactionalValue(transaction: collection.readTransaction, value: newValues)
            }
    }

    /**
     Observe the values returned by `predicate` after every collection change.
     - note:
     - Thread safe.
     - parameter matchingRawSql: Secondary indexed query to execute on collection change.
     */
    public func indexableValues(matchingRawSql clause: String) -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { return $0.0.findValuesWhere(clause) })
    }

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter matchingRawSql: Secondary indexed query to execute on collection change.
     - parameter prefilter: Executed before querying the collection to determine if the query is required.
     */
    public func indexableValues(matchingRawSql clause: String, prefilter: @escaping (_ changeSet: ChangeSet<String>, _ previousValues: [TCollection.Value]) -> Bool) -> IndexableObservable<[TCollection.Value]> {
        var previous: [TCollection.Value] = []

        let observable = self.filterChangeSet { (changeSet) -> Bool in
                return prefilter(changeSet, previous)
            }.map { (collection, changeSet) -> [TCollection.Value] in
                let newValues = collection.findValuesWhere(clause)
                previous = newValues
                return newValues
            }
        return IndexableObservable(observable: observable)
    }
}
