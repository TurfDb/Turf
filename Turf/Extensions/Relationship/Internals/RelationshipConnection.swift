import Foundation

internal class RelationshipConnection: ExtensionConnection {
    func readTransaction(transaction: ReadTransaction) -> RelationshipReadTransaction {
        return RelationshipReadTransaction()
    }

    func writeTransaction(transaction: ReadWriteTransaction) -> ExtensionWriteTransaction {
        return RelationshipWriteTransaction()
    }

    func prepare(db: SQLitePtr) {
        
    }
}
