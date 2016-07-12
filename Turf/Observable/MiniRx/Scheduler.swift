import Foundation

public protocol Scheduler {
    func schedule(action action: () -> Disposable) -> Disposable
}

public class QueueScheduler: Scheduler {
    private let queue: dispatch_queue_t
    private let requiresScheduling: () -> Bool
    public init(queue: dispatch_queue_t, requiresScheduling: () -> Bool) {
        self.queue = queue
        self.requiresScheduling = requiresScheduling
    }

    public func schedule(action action: () -> Disposable) -> Disposable {
        let disposable = AssignableDisposable()
        if requiresScheduling() {
            dispatch_async(queue) {
                disposable.disposable = action()
            }
        } else {
            disposable.disposable = action()
        }
        return disposable
    }
}
