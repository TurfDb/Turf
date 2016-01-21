public enum CallbackThread {
    case CallingThread
    case MainThread
    case OtherThread(dispatch_queue_t)
}