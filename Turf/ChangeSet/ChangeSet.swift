public final class ChangeSet<Key: Equatable> {
    // MARK: Public properties

    public fileprivate(set) var changes: [CollectionRowChange<Key>]
    public fileprivate(set) var allValuesRemoved: Bool

    // MARK: Internal properties

    // MARK: Object lifecycle

    internal init() {
        changes = []
        allValuesRemoved = false
    }

    // MARK: Public methods

    public func hasChangeForKey(_ key: Key) -> Bool {
        guard !allValuesRemoved else { return true }

        return changes.index {
            $0.key == key
        } != nil
    }

    public func mergeWithChangeSet(_ otherChanges: ChangeSet<Key>) {
        if otherChanges.allValuesRemoved {
            self.changes = otherChanges.changes
        } else {
            self.changes.append(contentsOf: otherChanges.changes)
        }
    }

    // MARK: Internal methods

    internal func recordValueInsertedWithKey(_ key: Key) {
        changes.append(.insert(key: key))
    }

    internal func recordValueUpdatedWithKey(_ key: Key) {
        changes.append(.update(key: key))
    }

    internal func recordValueRemovedWithKey(_ key: Key) {
        changes.append(.remove(key: key))
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
