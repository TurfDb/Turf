extension ObservableCollection where TCollection: IndexedCollection {
    public typealias Prefilter = (([TCollection.Value], ChangeSet<String>) -> Bool)?

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
    public func valuesWhere(clause: WhereClause, thread: CallbackThread = .CallingThread, prefilterChangeSet: Prefilter = nil) -> CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>> {
        let queryResultsObserver = CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>>(initalValue: [])

        let disposable =
            didChange(thread) { (collection, changeSet) in
                let canCheckPreviousValue = prefilterChangeSet != nil && queryResultsObserver.value.count > 0
                let shouldRequery = canCheckPreviousValue ? prefilterChangeSet!(queryResultsObserver.value, changeSet) : true

                if shouldRequery {
                    let queryResults = collection!.findValuesWhere(clause)
                    queryResultsObserver.setValue(queryResults, userInfo: collection!.readTransaction)
                }
        }

        queryResultsObserver.disposeBag.add(disposable)
        // If disposing ancestors, dispose this collection and all its child observers by removing from ObservingConnection
        queryResultsObserver.disposeBag.parent = self.disposeBag

        return queryResultsObserver
    }

    // MARK: Prepared query

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter preparedQuery: Prepared secondary indexed query to execute on collection change.
     - parameter thread: Thread to execute the prefilter and potential query on.
     - parameter prefilterChangeSet: Executed before querying the collection to determine if the query is required.
     */
    public func valuesWhere(preparedQuery: PreparedValuesWhereQuery<Collections>, thread: CallbackThread = .CallingThread, prefilterChangeSet: Prefilter = nil) -> CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>> {
        let queryResultsObserver = CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>>(initalValue: [])

        let disposable =
            didChange(thread) { (collection, changeSet) in
                let canCheckPreviousValue = prefilterChangeSet != nil && queryResultsObserver.value.count > 0
                let shouldRequery = canCheckPreviousValue ? prefilterChangeSet!(queryResultsObserver.value, changeSet) : true

                if shouldRequery {
                    let queryResults = collection!.findValuesWhere(preparedQuery)
                    queryResultsObserver.setValue(queryResults, userInfo: collection!.readTransaction)
                }
        }

        queryResultsObserver.disposeBag.add(disposable)
        // If disposing ancestors, dispose this collection and all its child observers by removing from ObservingConnection
        queryResultsObserver.disposeBag.parent = self.disposeBag

        return queryResultsObserver
    }

    // MARK: Raw SQL query

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
     - Thread safe.
     - parameter predicate: Secondary indexed query to execute on collection change.
     - parameter thread: Thread to execute the prefilter and potential query on.
     - parameter prefilterChangeSet: Executed before querying the collection to determine if the query is required.
     */
    public func valuesWhere(predicate: String, thread: CallbackThread = .CallingThread, prefilterChangeSet: Prefilter = nil) -> CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>> {
        let queryResultsObserver = CollectionTypeObserver<[TCollection.Value], ReadTransaction<Collections>>(initalValue: [])

        let disposable =
            didChange(thread) { (collection, changeSet) in
                let canCheckPreviousValue = prefilterChangeSet != nil && queryResultsObserver.value.count > 0
                let shouldRequery = canCheckPreviousValue ? prefilterChangeSet!(queryResultsObserver.value, changeSet) : true

                if shouldRequery {
                    let queryResults = collection!.findValuesWhere(predicate)
                    queryResultsObserver.setValue(queryResults, userInfo: collection!.readTransaction)
                }
        }

        queryResultsObserver.disposeBag.add(disposable)
        // If disposing ancestors, dispose this collection and all its child observers by removing from ObservingConnection
        queryResultsObserver.disposeBag.parent = self.disposeBag
        
        return queryResultsObserver
    }
}
