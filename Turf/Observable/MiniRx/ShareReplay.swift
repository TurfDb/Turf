import Foundation

public class ReplaySubject<Value>: Observable<Value>, ObserverType {

    // MARK: Private properties

    private var subscribers: [String: AnyObserver<Value>] = [:]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT
    private let bufferSize: Int
    private var previousValues = [Value]()

    // MARK: Public methods

    public init(bufferSize: Int) {
        self.bufferSize = bufferSize
        self.previousValues.reserveCapacity(bufferSize)
    }

    override func subscribe<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        let token = NSUUID().UUIDString
        subscribers[token] = observer.asObserver()

        for value in previousValues {
            observer.handle(next: value)
        }

        return BasicDisposable {
            self.subscribers[token] = nil
        }
    }

    public func handle(next next: Value) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        previousValues.append(next)
        if previousValues.count > bufferSize {
            previousValues.removeFirst()
        }

        for (_, observer) in subscribers {
            observer.handle(next: next)
        }
    }

    public func asObserver() -> AnyObserver<Value> {
        return AnyObserver(handleNext: {
            self.handle(next: $0)
        })
    }

    // MARK: Internal methods

    func safeSubscriberCount(handler: (Int) -> Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        handler(subscribers.count)
    }
}

///
/// Reference counted multicast observable that replays previous values on subscription.
/// Will only dispose of the source when all subscribers have been disposed.
///
class ShareReplay<Value>: Producer<Value> {

    // MARK: Private methods

    private let subject: ReplaySubject<Value>
    private let disposable: Disposable

    // MARK: Object lifecycle

    init(source: Observable<Value>, subject: ReplaySubject<Value>) {
        self.disposable = source.subscribe(subject)
        self.subject = subject
    }

    // MARK: Public methods

    override func run<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        let subscriberDisposable = subject.subscribe(observer)

        return BasicDisposable {
            subscriberDisposable.dispose()
            self.subject.safeSubscriberCount { count in
                if count == 0 {
                    self.disposable.dispose()
                }
            }
        }
    }
}

extension Observable {
    public func shareReplay(bufferSize bufferSize: Int = 1) -> Observable<Value> {
        return ShareReplay(source: self, subject: ReplaySubject(bufferSize: bufferSize))
    }
}
