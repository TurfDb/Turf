public protocol TypedObservable {
    typealias Value

    var value: Value { get }
}
