import Foundation

extension Observable {
    public func map<Mapped>(_ map: @escaping (Value) -> Mapped) -> Observable<Mapped> {
        return AnyObservable<Mapped>.create { (observer) -> Disposable in
            let mappedObserver = AnyObserver<Value>() { (value) in
                observer.handle(next: map(value))
            }

            return self.subscribe(mappedObserver)
        }
    }

    public func flatMap<Mapped>(_ map: @escaping (Value) -> Observable<Mapped>) -> Observable<Mapped> {
        return AnyObservable<Mapped>.create { (observer) -> Disposable in

            let disposeBag = DisposeBag()

            let flatMappedObserver = AnyObserver<Mapped>() { (value) in
                observer.handle(next: value)
            }

            let mappedObserver = AnyObserver<Value>() { (value) in
                let mappedValue = map(value)
                mappedValue.subscribe(flatMappedObserver).addTo(bag: disposeBag)
            }

            self.subscribe(mappedObserver).addTo(bag: disposeBag)
            return disposeBag
        }
    }
}
