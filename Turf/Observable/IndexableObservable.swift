import Foundation

open class IndexableObservable<Array: Collection>: Observable<Array> {
    open let first: Observable<Array.Iterator.Element?>
    open let last: Observable<Array.Iterator.Element?>

    fileprivate let wrappedObservable: Observable<Array>

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
//            return array.indices.contains(index) ? array[index] : nil
            return nil
        }
    }

    open subscript(observableIndex index: Array.Index) -> Observable<Array.Iterator.Element?> {
        return observe(index: index)
    }

    open override func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == Array {
        return wrappedObservable.subscribe(observer)
    }
}
