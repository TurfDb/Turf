public protocol Migration {
    func migrate(migrationId migrationId: UInt, operations: MigrationOperations, onProgress: (migrationId: UInt, MigrationState) -> Void)
}
