open class MigrationList {
    /// Number of registered migrations
    open var count: Int { return migrations.count }

    /// First migration to be executed
    open var firstMigrationIndex: UInt {
        return migrations.keys.reduce(UInt.max) { (min, index) -> UInt in
            return index < min ? index : min
        }
    }

    /// Last migration to be executed
    open var lastMigrationIndex: UInt {
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

    /**
     Register a migration.
     - parameter migration: Migration to run at `index`
     - parameter index: Index of the migration. This is not zero based and MUST START AT 1. It must be a strictly increasing number
     - warning: It is undefined behaviour if `index` does not strictly increase.
     */
    open func register(migration: Migration, index: UInt) {
        precondition(migrations[index] == nil, "Already register migration for \(index)")
        migrations[index] = migration
    }

    /**
     Register a migration.
     - parameter migration: Migration to run at `index`
     - parameter index: Index of the migration. This is not zero based and MUST START AT 1. It must be a strictly increasing number
     - warning: It is undefined behaviour if `index` does not strictly increase.
     */
    open func register(collectionMigration: CollectionMigration, index: UInt) {
        register(migration: CollectionMigrationOperator(migration: collectionMigration), index: index)
    }
}
