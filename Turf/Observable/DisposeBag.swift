public class DisposeBag: Disposable {
    // MARK: Public properties

    public private(set) var disposed: Bool

    // MARK: Internal properties

    var parent: Disposable?

    // MARK: Private properties

    private var disposables: [Disposable]

    // MARK: Object lifecycle

    public init() {
        self.disposed = false
        self.disposables  = []
    }

    // MARK: Public methods

    public func add(disposable: Disposable) {
        disposables.append(disposable)
    }

    public func dispose(disposeAncestors disposeAncestors: Bool = false) {
        guard !disposed else { return }

        for disposable in disposables {
            disposable.dispose(disposeAncestors: disposeAncestors)
        }

        disposables = []

        if disposeAncestors {
            parent?.dispose(disposeAncestors: disposeAncestors)
        }
        
        disposed = true
    }

    public func addToBag(disposeBag: DisposeBag) {
        disposeBag.add(self)
    }
}