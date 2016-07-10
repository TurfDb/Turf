import Foundation

public protocol ObserverType {
    associatedtype Value

    func handle(next next: Value)

    func asObserver() -> AnyObserver<Value>
}

// Someone who is listening to an observable
public class AnyObserver<Value>: ObserverType {
    public func handle(next next: Value) {
        thread.dispatchSynchronously { 
            self.handleNext(next)
        }
    }

    private let handleNext: ((Value) -> Void)
    private let thread: CallbackThread

    init(thread: CallbackThread, handleNext: ((Value) -> Void)) {
        self.handleNext = handleNext
        self.thread = thread
    }

    public func asObserver() -> AnyObserver<Value> {
        return self
    }
}
