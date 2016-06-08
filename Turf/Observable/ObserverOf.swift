public class ObserverOf<Value, UserInfo>: TypedObservable {
    // MARK: Public properties
    public typealias Callback = (Value, UserInfo?) -> Void

    public private(set) var value: Value

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var observers: [UInt64: (thread: CallbackThread, callback: Callback)]
    private var nextObserverToken = UInt64(0)
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Object lifecycle

    public init(initalValue: Value) {
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
    public func didChange(thread: CallbackThread = .CallingThread, callback: Callback) -> Disposable {
        OSSpinLockLock(&lock)

        let token = nextObserverToken
        observers[token] = (thread, callback)
        nextObserverToken += 1

        OSSpinLockUnlock(&lock)

        thread.dispatchAsynchronously {
            callback(self.value, nil)//TODO pass through real value
        }

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
    public func setValue(value: Value, userInfo: UserInfo?) {
        defer { OSSpinLockUnlock(&lock) }
        OSSpinLockLock(&lock)

        self.value = value
        onValueSet(value, userInfo: userInfo)
    }

    // MARK: Private methods

    private func onValueSet(newValue: Value, userInfo: UserInfo?) {
        for (_, observer) in observers {
            observer.thread.dispatchSynchronously {
                observer.callback(newValue, userInfo)
            }
        }
    }
}
