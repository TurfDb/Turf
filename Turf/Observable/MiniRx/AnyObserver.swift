import Foundation

public protocol ObserverType {
    associatedtype Value

    func handle(next: Value)

    func asObserver() -> AnyObserver<Value>
}

// Someone who is listening to an observable
open class AnyObserver<Value>: ObserverType {
    open func handle(next: Value) {
        self.handleNext(next)
    }

    fileprivate let handleNext: ((Value) -> Void)

    init(handleNext: @escaping ((Value) -> Void)) {
        self.handleNext = handleNext
    }

    open func asObserver() -> AnyObserver<Value> {
        return self
    }
}
