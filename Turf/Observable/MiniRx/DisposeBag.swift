open class DisposeBag: Disposable {

    // MARK: Public properties

    open private(set) var disposed: Bool

    // MARK: Private properties

    private var disposables: [Disposable]
    private var lock: OSSpinLock = OS_SPINLOCK_INIT

    // MARK: Object lifecycle

    public init() {
        self.disposed = false
        self.disposables  = []
    }

    // MARK: Public methods

    open func add(disposable: Disposable) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        disposables.append(disposable)
    }

    open func dispose() {
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
