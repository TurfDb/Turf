import Foundation

/// An Observable is a registry of handlers (ObserverTypes) that can be pushed values by a producer
open class Observable<Value> {
    open static func create(_ build: @escaping (_ observer: AnyObserver<Value>) -> Disposable) -> Observable<Value> {
        return AnyObservable(factory: build)
    }

    open static func just(_ value: Value) -> Observable<Value> {
        return AnyObservable(factory: { (observer) -> Disposable in
            observer.handle(next: value)
            return BasicDisposable { }
        })
    }

    open static func never() -> Observable<Value> {
        return AnyObservable(factory: { (observer) -> Disposable in
            return BasicDisposable { }
        })
    }

    func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        fatalError()
    }
    
    open func subscribeNext(_ observer: @escaping (Value) -> Void) -> Disposable {
        return subscribe(AnyObserver(handleNext: observer))
    }
}

open class Producer<Value>: Observable<Value> {
    override init() {
        super.init()
    }

    override func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        return run(observer)
    }

    func run<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        fatalError()
    }
}

open class AnyObservable<Value>: Producer<Value> {
    fileprivate let observableFactory: (AnyObserver<Value>) -> Disposable

    init(factory: @escaping (_ observer: AnyObserver<Value>) -> Disposable) {
        self.observableFactory = factory
    }

    override func run<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        return observableFactory(observer.asObserver())
    }
}
