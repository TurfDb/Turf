import Foundation

class Sink<Observer : ObserverType>: Disposable {
    var disposable: Disposable?

    private let observer: Observer

    init(observer: Observer) {
        self.observer = observer
    }

    deinit {
        dispose()
    }

    final func forwardOn(value value: Observer.Value) {
        observer.handle(next: value)
    }

    func dispose() {
        disposable?.dispose()
    }
}
