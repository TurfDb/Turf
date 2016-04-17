public class ObserverOf<T, DatabaseCollections: CollectionsContainer>: TypedObservable {
    // MARK: Public properties
    public typealias Value = T
    public typealias Callback = (T, ReadTransaction<DatabaseCollections>?) -> Void

    public private(set) var value: T

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var observers: [UInt64: (thread: CallbackThread, callback: Callback)]
    private var nextObserverToken = UInt64(0)
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Object lifecycle

    public init(initalValue: T) {
        self.value = initalValue
        self.disposeBag = DisposeBag()
        self.observers = [:]
    }

    deinit {
        disposeBag.dispose()
    }

    // MARK: Public methods

    /**
     - note:
        Thread safe.
     */
    public func didChange(thread: CallbackThread = .CallingThread, callback: (T, ReadTransaction<DatabaseCollections>?) -> Void) -> Disposable {
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

    /**
     - note:
        Thread safe
     */
    public func setValue(value: T, fromTransaction transaction: ReadTransaction<DatabaseCollections>?) {
        defer { OSSpinLockUnlock(&lock) }
        OSSpinLockLock(&lock)

        self.value = value
        onValueSet(value, transaction: transaction)
    }

    // MARK: Private methods

    private func onValueSet(newValue: T, transaction: ReadTransaction<DatabaseCollections>?) {
        for (_, observer) in observers {
            observer.thread.dispatchSynchronously {
                observer.callback(newValue, transaction)
            }
        }
    }
}
