public class ObserverOf<T>: TypedObservable {
    // MARK: Public properties
    public typealias Value = T

    public var value: T {
        didSet {
            onValueSet(value, transaction: nil)
        }
    }

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var observers: [T -> Void]

    // MARK: Object lifecycle

    public init(initalValue: T) {
        self.value = initalValue
        self.disposeBag = DisposeBag()
        self.observers = []
    }

    deinit {
        disposeBag.dispose()
    }

    public func didChange(thread: CallbackThread = .CallingThread, callback: (T, ReadTransaction) -> Void) -> Disposable {
        return BasicDisposable { }
    }

    public func setValue(value: T, fromTransaction transaction: ReadTransaction) {
        //TODO
    }

    // MARK: Internal methods

    // MARK: Private methods

    private func onValueSet(newValue: T, transaction: ReadTransaction?) {
        for observer in observers {
            observer(newValue)
        }
    }
}

public extension ObserverOf where T: CollectionType {
    var first: ObserverOf<T.Generator.Element?>? { return nil }
    var last: ObserverOf<T.Generator.Element?>? { return nil }
    subscript(index: T.Index) -> ObserverOf<T.Generator.Element?>? { return nil }

    func observeEachValue() -> [ObserverOf<T.Generator.Element>] {
        return []
    }

    func filter() -> ObserverOf<T>? {
        return nil
    }
}

//public func zip(observables: Observable ...) {
//    
//}
