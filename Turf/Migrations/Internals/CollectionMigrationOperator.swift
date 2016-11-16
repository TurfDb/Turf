internal class CollectionMigrationOperator {
    // MARK: Private properties

    fileprivate let migration: CollectionMigration

    // MARK: Object lifecycle

    init(migration: CollectionMigration) {
        self.migration = migration
    }
}

extension CollectionMigrationOperator: Migration {
    func migrate(migrationId: UInt, operations: MigrationOperations, onProgress: @escaping (_ migrationId: UInt, MigrationState) -> Void) {

        do {
            let totalRows = try totalNumberOfRows(operations)
            onProgress(migrationId, .unstarted(totalRows: totalRows))

            let collectionOperations = CollectionMigrationOperations(
                operations: operations,
                collectionName: migration.collectionName,
                toSchemaVersion: migration.toSchemaVersion)
            
            var currentIndex = UInt(0)
            try operations.enumerateValuesInCollection(migration.collectionName) { (index, key, version, value) -> Bool in
                guard version == self.migration.fromSchemaVersion else { return true }

                currentIndex += 1
                onProgress(migrationId, .migrating(currentIndex, of: totalRows))

                try self.migration.migrate(value, key: key, operations: collectionOperations)

                return true
            }

            onProgress(migrationId, .completed(.success(currentIndex)))
        } catch {
            onProgress(migrationId, .completed(.failure(error)))
        }
    }

    fileprivate func totalNumberOfRows(_ operations: MigrationOperations) throws -> UInt {
        return try operations.countOfValuesInCollection(migration.collectionName, atSchemaVersion: migration.fromSchemaVersion)
    }
}
