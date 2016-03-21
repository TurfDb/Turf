internal struct Dispatch {
    typealias Queue = dispatch_queue_t

    struct Queues {
        static var Main: Queue {
            return dispatch_get_main_queue()
        }

        static func create(type: DispatchQueueType, name: String) -> Queue {
            let queue: Queue

            switch type {
            case .SerialQueue:
                queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
            case .ConcurrentQueue:
                queue = dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)
            }
            return queue
        }

        static func makeContext(object: AnyObject) -> UnsafeMutablePointer<Void> {
            let temp = Unmanaged<AnyObject>.passUnretained(object).toOpaque()
            return UnsafeMutablePointer<Void>(temp)
        }

        static func setContext(context: UnsafeMutablePointer<Void>, key: UnsafePointer<Int8>, forQueue queue: Queue) {
            dispatch_queue_set_specific(queue, key, context, nil)
        }

        static func queueHasContext(context: UnsafeMutablePointer<Void>, forKey key: UnsafePointer<Int8>) -> Bool {
            return dispatch_get_specific(key) == context
        }

//        static func isOnQueue(queue: Queue, withKey key: UnsafePointer<Int8>) -> Bool {
//            let temp = Unmanaged<dispatch_queue_t>.passUnretained(queue).toOpaque()
//            let context = UnsafeMutablePointer<Void>(temp)
//            return dispatch_get_specific(key) == context
//        }
    }

    static func synchronouslyOn(queue: Queue, closure: () -> Void) {
        dispatch_sync(queue, closure)
    }

    static func synchronouslyOn(queue: Queue, closure: () throws -> Void) throws {
        var caughtError: ErrorType? = nil
        dispatch_sync(queue) {
            do {
                try closure()
            } catch {
                caughtError = error
            }
        }

        if let error = caughtError {
            throw error
        }
    }

    static func asynchronouslyOn(queue: Queue, closure: () -> Void) {
        dispatch_async(queue, closure)
    }
}
