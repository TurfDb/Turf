public protocol Migration {
    func migrate(migrationId: UInt, operations: MigrationOperations, onProgress: @escaping (_ migrationId: UInt, MigrationState) -> Void)
}
