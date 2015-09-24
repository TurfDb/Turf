public final class ChangeSet<Key> {
    // MARK: Public properties

    public private(set) var changes: [CollectionRowChange<Key>]
    public private(set) var allValuesRemoved: Bool

    // MARK: Internal properties

    // MARK: Object lifecycle

    internal init() {
        changes = []
        allValuesRemoved = false
    }

    // MARK: Public methods

    public func packChanges() -> [CollectionRowChange<Key>] {
        //If there's a remove then insert, call it an update? or an insert then deletion, remove the insert
        return []
    }

    // MARK: Internal methods

    internal func recordValueInsertedWithKey(key: Key) {
        changes.append(.Insert(key: key))
    }

    internal func recordValueUpdatedWithKey(key: Key) {
        changes.append(.Update(key: key))
    }

    internal func recordValueRemovedWithKey(key: Key) {
        changes.append(.Remove(key: key))
    }

    internal func recordAllValuesRemoved() {
        changes = []
        allValuesRemoved = true
    }

    internal func resetChangeSet() {
        changes = []
        allValuesRemoved = false
    }
}
