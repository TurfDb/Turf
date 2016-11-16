import Foundation

public protocol RxScheduler {
    func schedule(action:  @escaping () -> Disposable) -> Disposable
}

open class QueueScheduler: RxScheduler {
    fileprivate let queue: DispatchQueue
    fileprivate let requiresScheduling: () -> Bool
    public init(queue: DispatchQueue, requiresScheduling: @escaping () -> Bool) {
        self.queue = queue
        self.requiresScheduling = requiresScheduling
    }

    open func schedule(action: @escaping () -> Disposable) -> Disposable {
        let disposable = AssignableDisposable()
        if requiresScheduling() {
            queue.async {
                disposable.disposable = action()
            }
        } else {
            disposable.disposable = action()
        }
        return disposable
    }
}
