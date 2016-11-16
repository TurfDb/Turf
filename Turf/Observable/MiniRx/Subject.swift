import Foundation

/// Multicasts events sent by `handle(xyz:)` to all subscribers
open class Subject<Value>: Observable<Value>, ObserverType {
    public typealias ValueType = Value

    // MARK: Private properties

    private var subscribers: [String: AnyObserver<Value>] = [:]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    public override init() {
        
    }

    // MARK: Public methods

    override func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        let token = UUID().uuidString
        subscribers[token] = observer.asObserver()

        return BasicDisposable {
            self.subscribers[token] = nil
        }
    }

    open func handle(next: Value) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        for (_, observer) in subscribers {
            observer.handle(next: next)
        }
    }

    open func asObserver() -> AnyObserver<Value> {
        return AnyObserver(handleNext: {
            self.handle(next: $0)
        })
    }

    // MARK: Internal methods

    func safeSubscriberCount(_ handler: (Int) -> Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        handler(subscribers.count)
    }
}

/// Subject with an initial value
open class BehaviourSubject<Value>: Subject<Value> {
    private var currentValue: Value
    private var valueLock: OSSpinLock = OS_SPINLOCK_INIT

    public init(initialValue: Value) {
        self.currentValue = initialValue
        super.init()
    }

    override func subscribe<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        OSSpinLockLock(&valueLock)
        defer { OSSpinLockUnlock(&valueLock) }

        let disposable = super.subscribe(observer)
        observer.handle(next: currentValue)
        return disposable
    }

    open override func handle(next: Value) {
        OSSpinLockLock(&valueLock)
        defer { OSSpinLockUnlock(&valueLock) }

        super.handle(next: next)
        currentValue = next
    }
}
