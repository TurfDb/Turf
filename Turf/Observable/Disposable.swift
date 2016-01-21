public protocol Disposable {
    var disposed: Bool { get }

    func dispose(disposeAncestors disposeAncestors: Bool)
}
