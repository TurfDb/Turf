public class ObserverOf<T>: TypedObservable {
    // MARK: Public properties
    public typealias Value = T

    public private(set) var value: T

    public let disposeBag: DisposeBag

    // MARK: Private properties

    private var observers: [UInt64: (T, ReadTransaction?) -> Void]
    private var nextObserverToken = UInt64(0)

    // MARK: Object lifecycle

    public init(initalValue: T) {
        self.value = initalValue
        self.disposeBag = DisposeBag()
        self.observers = [:]
    }

    deinit {
        disposeBag.dispose()
    }

    public func didChange(thread: CallbackThread = .CallingThread, callback: (T, ReadTransaction?) -> Void) -> Disposable {

        let token = nextObserverToken
        observers[token] = callback//TODO Account for thread
        nextObserverToken += 1

        return BasicDisposable { [weak self] in
            self?.observers.removeValueForKey(token)
        }
    }

    public func setValue(value: T, fromTransaction transaction: ReadTransaction?) {
        self.value = value
        onValueSet(value, transaction: transaction)
    }

    // MARK: Private methods

    private func onValueSet(newValue: T, transaction: ReadTransaction?) {
        for (_, observer) in observers {
            observer(newValue, transaction)
        }
    }
}
