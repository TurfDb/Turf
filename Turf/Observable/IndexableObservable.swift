import Foundation

open class IndexableObservable<Array: Collection>: Observable<Array> {
    open let first: Observable<Array.Iterator.Element?>
    open let last: Observable<Array.Iterator.Element?>

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

    open func observe(index: Array.Index) -> Observable<Array.Iterator.Element?> {
        return wrappedObservable.map { array -> Array.Iterator.Element? in
            return array[safe: index]
        }
    }

    open subscript(observableIndex index: Array.Index) -> Observable<Array.Iterator.Element?> {
        return observe(index: index)
    }

    open override func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Array {
        return wrappedObservable.subscribe(observer)
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
