public class ObservableCollection<TCollection: Collection, Collections: CollectionsContainer>: TypedObservable, TypeErasedObservableCollection {
    public typealias Callback = (ReadCollection<TCollection, Collections>?, ChangeSet<String>) -> Void

    // MARK: Public properties
    public private(set) var value: ReadCollection<TCollection, Collections>?

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
    func processCollectionChanges(collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>) {
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
