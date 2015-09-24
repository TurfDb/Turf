import Foundation

internal class RelationshipWriteTransaction: ExtensionWriteTransaction {
    func handleValueInsertion<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, rowId: Int64, inCollection collection: TCollection) {

    }

    func handleValueUpdate<TCollection : Collection>(value: TCollection.Value, forKey primaryKey: String, rowId: Int64, inCollection collection: TCollection) {

    }

    func handleRemovalOfAllRowsInCollection<TCollection : Collection>(collection: TCollection) {

    }

    func handleRemovalOfRowsWithKeys<TCollection : Collection>(primaryKeys: [String], inCollection collection: TCollection) {
        
    }
}
