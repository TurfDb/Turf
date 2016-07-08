import Foundation

extension Observable {
    public func map<Mapped>(thread thread: CallbackThread = .CallingThread, map: (Value) -> Mapped) -> Observable<Mapped> {
        return AnyObservable<Mapped>.create { (observer) -> Disposable in
            let mappedObserver = AnyObserver<Value>(thread: thread) { (value) in
                observer.handle(next: map(value))
            }

            return self.subscribe(mappedObserver)
        }
    }

    public func flatMap<Mapped>(thread thread: CallbackThread = .CallingThread, map: (Value) -> Observable<Mapped>) -> Observable<Mapped> {
        return AnyObservable<Mapped>.create { (observer) -> Disposable in

            let disposeBag = DisposeBag()

            let flatMappedObserver = AnyObserver<Mapped>(thread: thread) { (value) in
                observer.handle(next: value)
            }

            let mappedObserver = AnyObserver<Value>(thread: thread) { (value) in
                let mappedValue = map(value)
                mappedValue.subscribe(flatMappedObserver).addTo(bag: disposeBag)
            }

            self.subscribe(mappedObserver).addTo(bag: disposeBag)
            return disposeBag
        }
    }
}
