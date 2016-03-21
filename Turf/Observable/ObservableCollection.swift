public class ObservableCollection<TCollection: Collection>: TypedObservable, TypeErasedObservableCollection {
    public typealias Callback = (ReadCollection<TCollection>?, ChangeSet<String>) -> Void

    // MARK: Public properties
    public private(set) var value: ReadCollection<TCollection>?

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var nextObserverToken = UInt64(0)
    private var observers: [UInt64: (thread: CallbackThread, callback: Callback)]

    // MARK: Object lifecycle

    init() {
        self.value = nil
        self.disposeBag = DisposeBag()
        self.observers = [:]
    }

    deinit {
        disposeBag.dispose(disposeAncestors: false)
    }

    // MARK: Public methods

    /**
     - returns: Disposable - call `dispose()` to remove the `didChange` callback.
     */
    public func didChange(thread: CallbackThread = .CallingThread, callback: Callback) -> Disposable {
        let token = nextObserverToken
        observers[token] = (thread, callback)
        nextObserverToken += 1

        return BasicDisposable { [weak self] in
            self?.observers.removeValueForKey(token)
        }
    }

    // MARK: Internal methods

    /**
     - parameter collection: Read collection on the most up to date snapshot after collection changes were committed.
     - parameter changeSet: The changes applied to bring `collection` to its current point.
     - parameter cacheUpdates: Updates made to the cache to bring `collection` to its current point.
     */
    func processCollectionChanges(collection: ReadCollection<TCollection>, changeSet: ChangeSet<String>) {
        value = collection

        for (_, observer) in observers {
            observer.thread.dispatchSynchronously {
                observer.callback(collection, changeSet)
            }
        }
    }
}

extension ObservableCollection where TCollection: IndexedCollection {
    public typealias Prefilter = (([TCollection.Value], ChangeSet<String>) -> Bool)?

    // MARK: Public methods

    public func valuesWhere(predicate: String, thread: CallbackThread = .CallingThread, prefilterChangeSet: Prefilter = nil) -> CollectionTypeObserver<[TCollection.Value]> {
        let queryResultsObserver = CollectionTypeObserver<[TCollection.Value]>(initalValue: [])

        let disposable =
        didChange(thread) { (collection, changeSet) in
            let canCheckPreviousValue = prefilterChangeSet != nil && queryResultsObserver.value.count > 0
            let shouldRequery = canCheckPreviousValue ? prefilterChangeSet!(queryResultsObserver.value, changeSet) : true

            if shouldRequery {
                let queryResults = collection!.findValuesWhere(predicate)
                queryResultsObserver.setValue(queryResults, fromTransaction: collection!.readTransaction)
            }
        }

        queryResultsObserver.disposeBag.add(disposable)
        // If disposing ancestors, dispose this collection and all its child observers by removing from ObservingConnection
        queryResultsObserver.disposeBag.parent = self.disposeBag

        return queryResultsObserver
    }
}
