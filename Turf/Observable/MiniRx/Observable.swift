import Foundation

/// An Observable is a registry of handlers (ObserverTypes) that can be pushed values by a producer
public class Observable<Value> {
    public static func create(build: (observer: AnyObserver<Value>) -> Disposable) -> Observable<Value> {
        return AnyObservable(factory: build)
    }

    public static func just(value: Value) -> Observable<Value> {
        return AnyObservable(factory: { (observer) -> Disposable in
            observer.handle(next: value)
            return BasicDisposable { }
        })
    }

    public static func never() -> Observable<Value> {
        return AnyObservable(factory: { (observer) -> Disposable in
            return BasicDisposable { }
        })
    }

    func subscribe<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        fatalError()
    }

    @warn_unused_result
    public func subscribeNext(on thread: CallbackThread = .CallingThread, observer: (Value) -> Void) -> Disposable {
        return subscribe(AnyObserver(thread: thread, handleNext: observer))
    }
}

public class Producer<Value>: Observable<Value> {
    override init() {
        super.init()
    }

    override func subscribe<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        return run(observer)
    }

    func run<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        fatalError()
    }

}

public class AnyObservable<Value>: Producer<Value> {
    private let observableFactory: (AnyObserver<Value>) -> Disposable

    init(factory: (observer: AnyObserver<Value>) -> Disposable) {
        self.observableFactory = factory
    }

    override func run<Observer: ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        return observableFactory(observer.asObserver())
    }
}
