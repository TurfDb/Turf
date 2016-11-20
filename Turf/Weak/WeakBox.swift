internal struct WeakBox<T> where T: AnyObject {
    weak var value : T?

    init (value: T) {
        self.value = value
    }
}
