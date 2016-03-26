public class MigrationList {
    public var count: Int { return migrations.count }

    public var firstMigrationIndex: UInt {
        return migrations.keys.reduce(UInt.max) { (min, index) -> UInt in
            return index < min ? index : min
        }
    }

    public var lastMigrationIndex: UInt {
        return migrations.keys.reduce(UInt.min) { (max, index) -> UInt in
            return index > max ? index : max
        }
    }

    // MARK: Internal properties

    private (set) var migrations: [UInt: Migration]

    // MARK: Object lifecycle

    public init() {
        self.migrations = [:]
    }

    // MARK: Public methods

    public func register(migration: Migration, index: UInt) {
        precondition(migrations[index] == nil, "Already register migration for \(index)")
        migrations[index] = migration
    }

    public func register(collectionMigration: CollectionMigration, index: UInt) {
        register(CollectionMigrationOperator(migration: collectionMigration), index: index)
    }
}