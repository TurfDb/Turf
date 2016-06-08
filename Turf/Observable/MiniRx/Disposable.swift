public protocol Disposable {
    func dispose()
}

extension Disposable {
    public func addTo(bag bag: DisposeBag) {
        bag.add(disposable: self)
    }
}
