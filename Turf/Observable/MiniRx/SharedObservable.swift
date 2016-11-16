import Foundation

///
/// Reference counted multicast observable.
/// Will only dispose of the source when all subscribers have been disposed.
///
open class SharedObservable<Value>: Producer<Value> {

    // MARK: Private methods

    fileprivate let subject: Subject<Value>
    fileprivate let disposable: Disposable

    // MARK: Object lifecycle

    init(source: Observable<Value>, subject: Subject<Value>) {
        self.disposable = source.subscribe(subject)
        self.subject = subject
    }

    // MARK: Public methods

    override func run<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
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

    public func multicast(subject: Subject<Value>) -> SharedObservable<Value> {
        return SharedObservable(source: self, subject: subject)
    }
}
