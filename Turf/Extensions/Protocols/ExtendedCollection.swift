/**
 Any collection that desires to run extensions post write commit must conform to `ExtendedCollection`
 */
public protocol ExtendedCollection {
    /// List of extensions that should be executed post write commit
    var associatedExtensions: [Extension] { get }
}
