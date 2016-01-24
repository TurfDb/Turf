public class CollectionTypeObserver<Collection: CollectionType where Collection.Index : BidirectionalIndexType>: ObserverOf<Collection> {
    public let first: ObserverOf<Collection.Generator.Element?>
    public let last: ObserverOf<Collection.Generator.Element?>

    public override init(initalValue: Collection) {
        first = ObserverOf(initalValue: nil)
        last = ObserverOf(initalValue: nil)

        super.init(initalValue: initalValue)

        didChange { [weak self] (newCollection, transaction) in
            self?.first.setValue(newCollection.first, fromTransaction: transaction)
            self?.last.setValue(newCollection.last, fromTransaction: transaction)
        }
    }

    public func observeIndex(index: Collection.Index) -> ObserverOf<Collection.Generator.Element?> {
        let observer = ObserverOf<Collection.Generator.Element?>(initalValue: nil)

        let disposeable =
        didChange { (newCollection, transaction) in
            observer.setValue(newCollection[index], fromTransaction: transaction)
        }

        observer.disposeBag.add(
            BasicDisposable {
                //TODO ancestors
                disposeable.dispose(disposeAncestors: false)
            }
        )

        return observer
    }

    //    public func filter() -> CollectionTypeObserver<Collection> {
    //        return CollectionTypeObserver(initalValue: nil)
    //    }
}

public extension CollectionTypeObserver where Collection: CollectionType, Collection.Index == Int {
    public func observeIndex(index: Collection.Index) -> ObserverOf<Collection.Generator.Element?> {
        let observer = ObserverOf<Collection.Generator.Element?>(initalValue: nil)

        let disposeable =
        didChange { (newCollection, transaction) in
            newCollection.last
            if index < newCollection.endIndex {
                observer.setValue(newCollection[index], fromTransaction: transaction)
            } else {
                observer.setValue(nil, fromTransaction: transaction)
            }
        }

        observer.disposeBag.add(
            BasicDisposable {
                //TODO ancestors
                disposeable.dispose(disposeAncestors: false)
            }
        )
        
        return observer
    }
}
