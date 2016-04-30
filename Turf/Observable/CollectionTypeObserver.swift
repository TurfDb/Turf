public class CollectionTypeObserver<Collection: CollectionType, UserInfo where Collection.Index : BidirectionalIndexType>: ObserverOf<Collection, UserInfo> {

    // MARK: Public properties

    public let first: ObserverOf<Collection.Generator.Element?, UserInfo>
    public let last: ObserverOf<Collection.Generator.Element?, UserInfo>

    // MARK: Object lifecycle

    public override init(initalValue: Collection) {
        first = ObserverOf(initalValue: nil)
        last = ObserverOf(initalValue: nil)

        super.init(initalValue: initalValue)

        didChange { [weak self] (newCollection, transaction) in
            self?.first.setValue(newCollection.first, userInfo: transaction)
            self?.last.setValue(newCollection.last, userInfo: transaction)
        }
    }

    // MARK: Public methods

    /**
     Observe any value at `index` in the collection.
     - note:
        Thread safe.
     */
    public func observeIndex(index: Collection.Index) -> ObserverOf<Collection.Generator.Element?, UserInfo> {
        let observer = ObserverOf<Collection.Generator.Element?, UserInfo>(initalValue: nil)

        let disposeable =
        didChange { (newCollection, transaction) in
            observer.setValue(newCollection[index], userInfo: transaction)
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

public extension CollectionTypeObserver where Collection: CollectionType, Collection.Index == Int {
    /**
     Observe any value at `index` in the collection. If `collection.count` becomes less than `index` 
     the updated value will become nil.
     - note:
        Thread safe.
     */
    public func observeIndex(index: Collection.Index) -> ObserverOf<Collection.Generator.Element?, UserInfo> {
        let observer = ObserverOf<Collection.Generator.Element?, UserInfo>(initalValue: nil)

        let disposeable =
        didChange { (newCollection, transaction) in
            newCollection.last
            if index < newCollection.endIndex {
                observer.setValue(newCollection[index], userInfo: transaction)
            } else {
                observer.setValue(nil, userInfo: transaction)
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
