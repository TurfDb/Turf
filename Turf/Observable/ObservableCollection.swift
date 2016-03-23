public class ObservableCollection<TCollection: Collection>: TypedObservable, TypeErasedObservableCollection {
    public typealias Callback = (ReadCollection<TCollection>?, ChangeSet<String>) -> Void

    // MARK: Public properties
    public private(set) var value: ReadCollection<TCollection>?

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var nextObserverToken = UInt64(0)
    private var observers: [UInt64: (thread: CallbackThread, callback: Callback)]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

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
     - note:
        - Thread safe.
     - returns: Disposable - call `dispose()` to remove the `didChange` callback.
     */
    public func didChange(thread: CallbackThread = .CallingThread, callback: Callback) -> Disposable {
        OSSpinLockLock(&lock)

        let token = nextObserverToken
        observers[token] = (thread, callback)
        nextObserverToken += 1

        OSSpinLockUnlock(&lock)

        return BasicDisposable { [weak self] in
            guard let strongSelf = self else { return }
            defer { OSSpinLockUnlock(&strongSelf.lock) }
            OSSpinLockLock(&strongSelf.lock)

            self?.observers.removeValueForKey(token)
        }
    }

    // MARK: Internal methods

    /**
     - note:
        - Thread safe.
     - parameter collection: Read collection on the most up to date snapshot after collection changes were committed.
     - parameter changeSet: The changes applied to bring `collection` to its current point.
     - parameter cacheUpdates: Updates made to the cache to bring `collection` to its current point.
     */
    func processCollectionChanges(collection: ReadCollection<TCollection>, changeSet: ChangeSet<String>) {
        defer { OSSpinLockUnlock(&lock) }
        OSSpinLockLock(&lock)

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

    /**
     Observe the values returned by `predicate` after a collection change.
     If the query is expensive, the collection change set can be examined first by using `prefilterChangeSet`.
     - note:
        - Thread safe.
     - parameter predicate: Secondary indexed query to execute on collection change.
     - parameter thread: Thread to execute the prefilter and potential query on.
     - parameter prefilterChangeSet: Executed before querying the collection to determine if the query is required.
     */
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
