import Foundation

public class ObservableCollection<TCollection: Collection, Collections: CollectionsContainer>: SharedObservable<(collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)>, TypeErasedObservableCollection {
    public typealias CollectionChanges = (collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)

    // MARK: Object lifecycle

    init(collectionChangedObservable: Observable<CollectionChanges>, collection: ReadCollection<TCollection, Collections>) {
        let connection = collection.readTransaction.connection
        let queue = connection.connectionQueue
        
        let noChanges = ChangeSet<String>()
        let subject = BehaviourSubject<CollectionChanges>(initialValue: (collection, noChanges))
        // BehaviourSubject will immediately trigger a `next` value of the collection. Which won't get dispatched
        // on the connection queue so we must fix this.
        let scheduler = QueueScheduler(queue: queue, isOnQueue: {
            return connection.isOnConnectionQueue()
        })        

        super.init(source: collectionChangedObservable.subscribeOn(scheduler), subject: subject)
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
