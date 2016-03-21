public final class ChangeSet<Key: Equatable> {
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

    public func hasChangeForKey(key: Key) -> Bool {
        guard !allValuesRemoved else { return true }

        return changes.indexOf {
            $0.key == key
        } != nil
    }

    public func mergeWithChangeSet(otherChanges: ChangeSet<Key>) {
        if otherChanges.allValuesRemoved {
            self.changes = otherChanges.changes
        } else {
            self.changes.appendContentsOf(otherChanges.changes)
        }
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

    internal func copy() -> ChangeSet<Key> {
        let changeSet = ChangeSet<Key>()
        changeSet.changes = self.changes
        changeSet.allValuesRemoved = self.allValuesRemoved
        return changeSet
    }
}

extension ChangeSet: CustomDebugStringConvertible {
    public var debugDescription: String {
        var description = ""

        if changes.count == 0 && allValuesRemoved == false {
            description = "No changes"
        } else {
            description = "Changes: \(changes.debugDescription)\n"
            description += "All keys removed: \(allValuesRemoved)\n"
        }

        return description
    }
}
