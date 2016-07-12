import Foundation

///
/// Reference counted multicast observable.
/// Will only dispose of the source when all subscribers have been disposed.
///
public class SharedObservable<Value>: Producer<Value> {
    public typealias ValueType = Value

    // MARK: Private methods

    private let subject: Subject<Value>
    private let disposable: Disposable

    // MARK: Object lifecycle

    init(source: Observable<Value>, subject: Subject<Value>) {
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
    public func share() -> SharedObservable<Value> {
        return multicast(subject: Subject())
    }

    public func multicast(subject subject: Subject<Value>) -> SharedObservable<Value> {
        return SharedObservable(source: self, subject: subject)
    }
}
