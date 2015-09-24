public protocol CollectionWithRelationships: Collection, ExtendedCollection {
    typealias Relationships: RelatedCollections

    var relationships: Relationships { get }
}
