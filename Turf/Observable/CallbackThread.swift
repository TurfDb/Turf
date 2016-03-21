public enum CallbackThread {
    case CallingThread
    case MainThread
    case OtherThread(dispatch_queue_t)

    // MARK: Public properties

    public var queue: dispatch_queue_t? {
        switch self {
        case .MainThread: return dispatch_get_main_queue()
        case .OtherThread(let queue): return queue
        case .CallingThread: return nil
        }
    }

    // MARK: Public methods

    public func dispatchSynchronously(closure: () -> Void) {
        if let queue = self.queue {
            Dispatch.synchronouslyOn(queue, closure: closure)
        } else {
            closure()
        }
    }

    public func dispatchSynchronously(closure: () throws -> Void) throws {
        if let queue = self.queue {
            try Dispatch.synchronouslyOn(queue, closure: closure)
        } else {
            try closure()
        }
    }
}
