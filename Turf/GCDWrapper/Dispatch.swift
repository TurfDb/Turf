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

        static func setContext(context: AnyObject, inout key: AnyObject, forQueue queue: Queue) {
            let unmanagedContext = Unmanaged.passRetained(context).toOpaque()
            let contextPointer = UnsafeMutablePointer<Void>(unmanagedContext)
            dispatch_queue_set_specific(queue, &key, contextPointer, nil)
        }

        static func hasContextForCurrentQueue(key key: String) -> Bool {
            return dispatch_get_specific(key) != nil
        }
    }

    static func synchronouslyOn(queue: Queue, closure: () -> Void) {
        dispatch_sync(queue, closure)
    }

    static func asynchronouslyOn(queue: Queue, closure: () -> Void) {
        dispatch_async(queue, closure)
    }
}
