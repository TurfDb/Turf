public protocol Migration {
    func migrate(index index: UInt, onProgress: (index: UInt, MigrationState) -> Void)
}
