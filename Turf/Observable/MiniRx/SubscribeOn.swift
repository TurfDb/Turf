import Foundation

class SubscribeOnSink<Value, Observer: ObserverType where Observer.Value == Value>: Sink<Observer>, ObserverType {
    typealias Parent = SubscribeOn<Value>

    let parent: Parent

    init(parent: Parent, observer: Observer) {
        self.parent = parent
        super.init(observer: observer)
    }

    func handle(next next: Value) {
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
    private let source: Observable<Value>
    let scheduler: Scheduler

    init(source: Observable<Value>, scheduler: Scheduler) {
        self.source = source
        self.scheduler = scheduler
    }

    override func run<Observer : ObserverType where Observer.Value == Value>(observer: Observer) -> Disposable {
        //calling subscribe, calls run
        let sink = SubscribeOnSink(parent: self, observer: observer)
        //calling run on sink
        sink.disposable = sink.run()
        return sink
    }
}

extension Observable {
    public func subscribeOn(scheduler: Scheduler) -> Observable<Value> {
        return SubscribeOn(source: self, scheduler: scheduler)
    }
}
