public protocol TypedObservable {
    associatedtype Value

    var value: Value { get }
}
