public class BasicDisposable: Disposable {
    // MARK: Public properties

    public private(set) var disposed: Bool

    // MARK: Internal properties

    var parent: Disposable?

    // MARK: Private properties

    private var callback: (() -> Void)?

    // MARK: Object lifecycle

    init(callback: () -> Void) {
        self.disposed = false
        self.callback = callback
    }

    // MARK: Public methods

    public func dispose(disposeAncestors disposeAncestors: Bool = false) {
        guard !disposed else { return }
        callback?()
        callback = nil

        if disposeAncestors {
            parent?.dispose(disposeAncestors: disposeAncestors)
        }
    
        self.disposed = true
    }
}
