import Foundation

public protocol RelatedCollections {
    var toOneRelationships: [CollectionProperty] { get }
    var toManyRelationships: [CollectionProperty] { get }
}
