import Foundation

class Sink<Observer : ObserverType>: Disposable {
    var disposable: Disposable?

    private let observer: Observer

    init(observer: Observer) {
        self.observer = observer
    }

    final func forwardOn(value value: Observer.Value) {
        observer.handle(next: value)
    }

    func dispose() {
        disposable?.dispose()
    }
}


public protocol Scheduler {
    func schedule(action action: () -> Disposable) -> Disposable
}

public class QueueScheduler: Scheduler {
    private let queue: dispatch_queue_t
    private let requiresScheduling: () -> Bool
    public init(queue: dispatch_queue_t, isOnQueue: () -> Bool) {
        self.queue = queue
        self.requiresScheduling = isOnQueue
    }

    public func schedule(action action: () -> Disposable) -> Disposable {
        let disposable = AssignableDisposable()
        if requiresScheduling() {
            dispatch_async(queue) {
                disposable.disposable = action()
            }
        } else {
            disposable.disposable = action()
        }
        return disposable
    }
}

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
        return AnyObserver(thread: .CallingThread, handleNext: { next in
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
