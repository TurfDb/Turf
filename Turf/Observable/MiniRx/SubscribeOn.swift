import Foundation

class SubscribeOnSink<Value, Observer: ObserverType>: Sink<Observer>, ObserverType where Observer.Value == Value {
    typealias Parent = SubscribeOn<Value>

    let parent: Parent

    init(parent: Parent, observer: Observer) {
        self.parent = parent
        super.init(observer: observer)
    }

    func handle(next: Value) {
        forwardOn(value: next)
    }

    func asObserver() -> AnyObserver<Value> {
        return AnyObserver(handleNext: { next in
            self.handle(next: next)
        })
    }

    func run() -> Disposable {
        return parent.scheduler.schedule { () -> Disposable in
            return self.parent.source.subscribe(self)
        }
    }
}

class SubscribeOn<Value>: Producer<Value> {
    fileprivate let source: Observable<Value>
    let scheduler: RxScheduler

    init(source: Observable<Value>, scheduler: RxScheduler) {
        self.source = source
        self.scheduler = scheduler
    }

    override func run<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Value {
        //calling subscribe, calls run
        let sink = SubscribeOnSink(parent: self, observer: observer)
        //calling run on sink
        sink.disposable = sink.run()
        return sink
    }
}

extension Observable {
    public func subscribeOn(_ scheduler: RxScheduler) -> Observable<Value> {
        return SubscribeOn(source: self, scheduler: scheduler)
    }
}
