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

    public convenience init(builder: (register: (Migration, UInt) -> Void) -> Void) {
        self.init()
        builder(register: self.register)
    }

    // MARK: Public methods

    public func register(migration: Migration, index: UInt) {

    }
}