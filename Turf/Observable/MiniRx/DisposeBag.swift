public class DisposeBag: Disposable {

    // MARK: Public properties

    public private(set) var disposed: Bool

    // MARK: Private properties

    private var disposables: [Disposable]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Object lifecycle

    public init() {
        self.disposed = false
        self.disposables  = []
    }

    // MARK: Public methods

    public func add(disposable disposable: Disposable) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        disposables.append(disposable)
    }

    public func dispose() {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        guard !disposed else { return }

        for disposable in disposables {
            disposable.dispose()
        }

        disposables = []
        disposed = true
    }
}
