import Foundation

public protocol ObserverType {
    associatedtype Value

    func handle(next next: Value)

    func asObserver() -> AnyObserver<Value>
}

// Someone who is listening to an observable
public class AnyObserver<Value>: ObserverType {
    public func handle(next next: Value) {
        self.handleNext(next)
    }

    private let handleNext: ((Value) -> Void)

    init(handleNext: ((Value) -> Void)) {
        self.handleNext = handleNext
    }

    public func asObserver() -> AnyObserver<Value> {
        return self
    }
}
