public protocol FTSProperties {
    typealias TCollection: Collection
    var allProperties: [FTSProperty<TCollection>] { get }
}
