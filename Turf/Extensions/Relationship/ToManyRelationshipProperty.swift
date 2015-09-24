public struct ToManyRelationshipProperty<SCollection: CollectionWithRelationships, DCollection: Collection>: CollectionProperty {
    // MARK: Public properties

    public let name: String

    // MARK: Internal properties

    internal let destinationKeysFromSourceValue: (SCollection.Value, ReadCollection<DCollection>?) -> [String]
    internal let sourceKeyFromSourceValue: (SCollection.Value -> String)

    // MARK: Object lifecycle

    public init(
        name: String,
        sourceKeyFromSourceValue: (SCollection.Value -> String),
        destinationKeysFromSourceValue: (SCollection.Value, ReadCollection<DCollection>?) -> [String]) {
        self.name = name
        self.sourceKeyFromSourceValue = sourceKeyFromSourceValue
        self.destinationKeysFromSourceValue = destinationKeysFromSourceValue
    }
}
