internal class CollectionMigrationOperator {
    // MARK: Private properties

    private let migration: CollectionMigration

    // MARK: Object lifecycle

    init(migration: CollectionMigration) {
        self.migration = migration
    }
}

extension CollectionMigrationOperator: Migration {
    func migrate(migrationId migrationId: UInt, operations: MigrationOperations, onProgress: (migrationId: UInt, MigrationState) -> Void) {

        let totalRows = totalNumberOfRows(operations)
        onProgress(migrationId: migrationId, .Unstarted(totalRows: totalRows))

        do {
            let collectionOperations = CollectionMigrationOperations(
                operations: operations,
                collectionName: migration.collectionName,
                toSchemaVersion: migration.toSchemaVersion)
            
            var currentIndex = UInt(0)
            try operations.enumerateValuesInCollection(migration.collectionName) { (index, key, version, value) -> Bool in
                guard version == self.migration.fromSchemaVersion else { return true }

                currentIndex += 1
                onProgress(migrationId: migrationId, .Migrating(currentIndex, of: totalRows))

                try self.migration.migrate(value, key: key, operations: collectionOperations)

                return true
            }

            onProgress(migrationId: migrationId, .Completed(.Success(currentIndex)))
        } catch {
            onProgress(migrationId: migrationId, .Completed(.Failure(error)))
        }
    }

    private func totalNumberOfRows(operations: MigrationOperations) -> UInt {
        return operations.countOfValuesInCollection(migration.collectionName, atVersion: migration.fromSchemaVersion)
    }
}
