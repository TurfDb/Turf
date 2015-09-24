import Foundation

public protocol FTSCollection: Collection, ExtendedCollection {
    typealias TextProperties: FTSProperties

    var fts: FullTextSearch<Self, TextProperties> { get }
    var textProperties: TextProperties { get }
}
