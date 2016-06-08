import Foundation

public class IndexableObservable<Array: CollectionType>: Observable<Array> {
    public let first: Observable<Array.Generator.Element?>
    public let last: Observable<Array.Generator.Element?>

    private let wrappedObservable: Observable<Array>

    init(observable: Observable<Array>) {
        wrappedObservable = observable

        first = wrappedObservable.map { array in
            return array.first
        }

        last = wrappedObservable.map { array in
            return array.first
        }
    }

    public func observe(index index: Array.Index) -> Observable<Array.Generator.Element?> {
        return wrappedObservable.map { array in
            return array[safe: index]
        }
    }

    public subscript(observableIndex index: Array.Index) -> Observable<Array.Generator.Element?> {
        return observe(index: index)
    }

    public override func subscribe<Observer: ObserverType where Observer.Value == Array>(observer: Observer) -> Disposable {
        return wrappedObservable.subscribe(observer)
    }
}

extension CollectionType {
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
