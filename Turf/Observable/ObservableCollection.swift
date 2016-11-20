import Foundation

open class ObservableCollection<TCollection: TurfCollection, Collections: CollectionsContainer>: Producer<(collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)>, TypeErasedObservableCollection {
    public typealias CollectionChanges = (collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)

    private let collectionChangedObservable: Observable<CollectionChanges>

    // MARK: Object lifecycle

    init(collectionChangedObservable: Observable<CollectionChanges>, collection: ReadCollection<TCollection, Collections>) {
        let connection = collection.readTransaction.connection
        let queue = connection.connectionQueue

        // BehaviourSubject will immediately trigger a `next` value of the collection. Which won't get dispatched
        // on the connection queue so we must fix this.
        let scheduler = QueueScheduler(queue: queue, requiresScheduling: { [weak connection] in
            return !(connection?.isOnConnectionQueue() ?? false)
        })

        let noChanges = ChangeSet<String>()
        let subject = BehaviourSubject<CollectionChanges>(initialValue: (collection, noChanges))

        self.collectionChangedObservable = collectionChangedObservable
            .multicast(subject: subject)
            .subscribeOn(scheduler)
    }

    override func run<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.Value == CollectionChanges {
        return collectionChangedObservable.subscribe(observer)
    }

    open func allValues() -> Observable<TransactionalValue<[TCollection.Value], Collections>> {
        return self.map { collection, changeSet in
            return TransactionalValue(transaction: collection.readTransaction, value: Array(collection.allValues))
        }
    }

    open func observableIndexedValues() -> IndexableObservable<[TCollection.Value]> {
        return IndexableObservable(observable: self.map { collection, changeSet in
            return Array(collection.allValues)
        })
    }

    open func filterChangeSet(_ filter: @escaping (ChangeSet<String>) -> Bool) -> Observable<CollectionChanges>  {
        return self.flatMap { result in
            if filter(result.changeSet) {
                return Observable.just(result)
            } else {
                return Observable.never()
            }
        }
    }
}
