import Foundation

public class ObservableCollection<TCollection: Collection, Collections: CollectionsContainer>: SharedObservable<(collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)>, TypeErasedObservableCollection {
    public typealias CollectionChanges = (collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)

    // MARK: Object lifecycle

    init(collectionChangedObservable: Observable<CollectionChanges>, collection: ReadCollection<TCollection, Collections>) {
        let noChanges = ChangeSet<String>()
        super.init(source: collectionChangedObservable, subject: BehaviourSubject(initialValue: (collection, noChanges)))
    }

    public func allValues() -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { collection, changeSet in
            return TransactionalValue(transaction: collection.readTransaction, value: Array(collection.allValues))
        }
    }

    public func allValues() -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { collection, changeSet in
            return Array(collection.allValues)
        })
    }

    public func filterChangeSet(filter: (ChangeSet<String>) -> Bool) -> Observable<CollectionChanges>  {
        return self.flatMap { result in
            if filter(result.changeSet) {
                return Observable.just(result)
            } else {
                return Observable.never()
            }
        }
    }
}
