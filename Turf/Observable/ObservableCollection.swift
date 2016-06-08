//import RxSwift

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

// TODO Implement RxSwift extensions that map as close to 100% to my mini internal version.
// TODO Implement specific value changes observing
// TODO Test out zipping specific value change observables as producing change Events.
// zip(checkUpdatedObservable, lineItemInsertedObservable).subscribeNext { (check, lineItem) in postEvent(LineItemAdded()) }

//extension ObservableCollection: ObservableType {
//    public typealias E = (collection: ReadCollection<TCollection, Collections>, changeSet: ChangeSet<String>)
//
//    public func asObservable() -> RxSwift.Observable<ObservableCollection.E> {
//        return Observable.create { observer in
//            return self.subscribe(observer)
//        }
//    }
//
//    public func subscribe<O : ObserverType where O.E == ObservableCollection.E>(observer: O) -> RxSwift.Disposable {
//        let didChangeDisposable = self.didChange(callback: { (collection, changeSet) in
//            observer.on(.Next((collection: collection, changeSet: changeSet)))
//        })
//
//        return AnonymousDisposable {
//            didChangeDisposable.dispose()
//        }
//    }
//
////    public func all() -> RxSwift.Observable<[TCollection.Value]> {
////        return asObservable().map { collection, changeSet in
////            return Array(collection.allValues)
////        }
////    }
//}
