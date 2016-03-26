public protocol Migration {
    func migrate(index index: UInt, operations: MigrationOperations, onProgress: (index: UInt, MigrationState) -> Void)
}
