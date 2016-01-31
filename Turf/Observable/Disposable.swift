public protocol Disposable {
    var disposed: Bool { get }

    func dispose(disposeAncestors disposeAncestors: Bool)

    func addToBag(disposeBag: DisposeBag)
}
