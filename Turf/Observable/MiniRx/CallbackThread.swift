public enum CallbackThread {
    case callingThread
    case mainThread
    case otherThread(DispatchQueue)

    // MARK: Public properties

    public var queue: DispatchQueue? {
        switch self {
        case .mainThread: return Thread.isMainThread ? nil : DispatchQueue.main
        case .otherThread(let queue): return queue
        case .callingThread: return nil
        }
    }

    // MARK: Public methods

    public func dispatchSynchronously(_ closure: () -> Void) {
        if let queue = self.queue {
            queue.sync(execute: closure)
        } else {
            closure()
        }
    }

    public func dispatchSynchronously(_ closure: () throws -> Void) throws {
        if let queue = self.queue {
            try queue.sync(execute: closure)
        } else {
            try closure()
        }
    }

    public func dispatchAsynchronously(_ closure: @escaping () -> Void) {
        if let queue = self.queue {
            queue.async(execute: closure)
        } else {
            closure()
        }
    }
}
