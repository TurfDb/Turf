import Foundation

public class Relationship: Extension {
    public let uniqueName: String = ""

    public init() {}

    public func newConnection(connection: Connection) -> ExtensionConnection {
        return RelationshipConnection()
    }
}
