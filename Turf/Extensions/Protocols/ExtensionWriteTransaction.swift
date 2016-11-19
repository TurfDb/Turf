/**
 Extension's write transaction which handles all modifiations to collections
 - warning: If you modify a collection in one of these handlers any collection extensions will not be triggered. Hopefully in the future there will be a recursive post-transaction handler that can deal with this.
 */
public protocol ExtensionWriteTransaction {
    /**
     Process a value insertion
     - parameter value: The value inserted
     - parameter primaryKey: The primary key of the value inserted
     - parameter collection: The collection the value was inserted into
     */
    func handleValueInsertion<TCollection: TurfCollection>(value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws

    /**
     Process a value update
     - parameter value: The updated value
     - parameter primaryKey: The primary key of the updated value
     - parameter collection: The collection the value was updated in
     */
    func handleValueUpdate<TCollection: TurfCollection>(value: TCollection.Value, forKey primaryKey: String, inCollection collection: TCollection) throws

    /**
     Process the removal of multiple rows
     - note: rowids are not given here for efficency reasons
     - parameter primaryKeys: The keys of the values removed
     - parameter collection: The collection from which the values were removed
     */
    func handleRemovalOfRows<TCollection: TurfCollection>(withKeys: [String], inCollection collection: TCollection) throws

    /**
     A handler for more efficiently handling the removal of all values in a collection
     - note: 
        - `handleRemovalOfRowsWithKeys(_:inCollection:)` will not be called when removing all values.
        - rowids and keys are not given here for efficency reasons
     - parameter collection: The collection from which all values were removed
     */
    func handleRemovalOfAllRows<TCollection: TurfCollection>(collection: TCollection) throws

}
