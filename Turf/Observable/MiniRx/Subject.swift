import Foundation

/// Multicasts events sent by `handle(xyz:)` to all subscribers
public class Subject<Value>: Observable<Value>, ObserverType {
    public typealias ValueType = Value

    // MARK: Private properties

    private var subscribers: [String: AnyObserver<Value>] = [:]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Public methods

    public override func subscribe<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        let token = NSUUID().UUIDString
        subscribers[token] = observer.asObserver()

        return BasicDisposable {
            self.subscribers[token] = nil
        }
    }

    public func handle(next next: Value) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        for (_, observer) in subscribers {
            observer.handle(next: next)
        }
    }

    public func asObserver() -> AnyObserver<Value> {
        return AnyObserver(handleNext: { self.handle(next: $0) })
    }

    // MARK: Internal methods

    func safeSubscriberCount(handler: (Int) -> Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        handler(subscribers.count)
    }
}

/// Subject with an initial value
public class BehaviourSubject<Value>: Subject<Value> {
    private var currentValue: Value
    private var valueLock: OSSpinLock = OS_SPINLOCK_INIT

    public init(initialValue: Value) {
        self.currentValue = initialValue
        super.init()
    }

    public override func subscribe<Observer : ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        OSSpinLockLock(&valueLock)
        defer { OSSpinLockUnlock(&valueLock) }

        let disposable = super.subscribe(observer)
        observer.handle(next: currentValue)
        return disposable
    }

    public override func handle(next next: Value) {
        OSSpinLockLock(&valueLock)
        defer { OSSpinLockUnlock(&valueLock) }

        super.handle(next: next)
        currentValue = next
    }
}