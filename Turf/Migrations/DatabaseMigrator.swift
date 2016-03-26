import Foundation

public class DatabaseMigrator {
    public enum Error: ErrorType {
        case MigrationsCurrentlyRunning
        case MissingMigration(missingIndex: UInt)
    }

    // MARK: Public properties

    public let migrationList: MigrationList

    public var migrationRequired: Bool {
        return migrationList.count > 0 && false
    }

    public var onNextMigration: ((index: UInt, total: UInt) -> Void)?
    public var onMigrationProgressChanged: ((index: UInt, progress: UInt, of: UInt) -> Void)?

    // MARK: Private properties

    private var sqlite: SQLiteAdapter!
    private var migrationOperations: MigrationOperations!
    private var startTimestamp: NSDate?
    private var stopTimestamp: NSDate?

    private var migrating: Bool {
        didSet {
            if !oldValue && migrating { startTimestamp = NSDate() }
            else if oldValue && !migrating { stopTimestamp = NSDate() }
        }
    }

    private var onMigrationsCompleted: (Result<NSTimeInterval> -> Void)?

    // MARK: Object lifecycle

    public init(databaseUrl: NSURL, migrationList: MigrationList) throws {
        self.migrationList = migrationList
        self.migrating = false

        do {
            self.sqlite = try SQLiteAdapter(sqliteDatabaseUrl: databaseUrl)
            self.migrationOperations = MigrationOperations(sqlite: self.sqlite)
        } catch {
            self.sqlite = nil
            self.migrationOperations = nil
            throw error
        }
    }

    // MARK: Internal methods

    func migrate(onCompletion: Result<NSTimeInterval> -> Void) {
        guard !migrating else {
            onCompletion(.Failure(Error.MigrationsCurrentlyRunning))
            return
        }

        migrating = true

        guard migrationRequired else {
            sqlite.close()
            migrating = false
            onCompletion(.Success(totalMigrationTime()))
            return
        }

        onMigrationsCompleted = onCompletion

        do {
            try migrate(migrationList.firstMigrationIndex)
        } catch {
            onCompletion(.Failure(error))
        }
    }

    // MARK: Private methods

    private func migrate(index: UInt) throws {
        switch migrationForIndex(index) {
        case .Success(let migration):
            try sqlite.beginDeferredTransaction()
            migration.migrate(migrationId: index, operations: migrationOperations, onProgress: migrationProgress)
            break
        case .Failure(let error):
            migrationProgress(index: index, state: MigrationState.Completed(.Failure(error)))
        }
    }

    private func migrationProgress(index index: UInt, state: MigrationState) {
        switch state {
        case .Unstarted(totalRows: let total):
            onNextMigration?(index: index, total: total)
        case .Migrating(let currentPosition, let total):
            onMigrationProgressChanged?(index: index, progress: currentPosition, of: total)
        case .Completed(let result):
            switch result {
            case .Success(let total):
                migrationSuccess(index, totalRowsMigrated: total)
            case .Failure(let error):
                migrationFailure(index, error: error)
            }
        }
    }

    private func migrationSuccess(index: UInt, totalRowsMigrated: UInt) {
        do {
            try sqlite.commitTransaction()
        } catch {
            migrationFailure(index, error: error)
        }

        onMigrationProgressChanged?(index: index, progress: totalRowsMigrated, of: totalRowsMigrated)
        guard index != self.migrationList.lastMigrationIndex else {
            sqlite.close()
            migrating = false
            onMigrationsCompleted!(.Success(totalMigrationTime()))
            return
        }

        do {
            try migrate(index + 1)
        } catch {
            migrationFailure(index, error: error)
        }
    }

    private func migrationFailure(index: UInt, error: ErrorType) {
        let _ = try? sqlite.rollbackTransaction()
        sqlite.close()
        onMigrationsCompleted!(.Failure(error))
    }

    private func migrationForIndex(index: UInt) -> Result<Migration> {
        if let migration = migrationList.migrations[index] {
            return .Success(migration)
        } else {
            return .Failure(Error.MissingMigration(missingIndex: index))
        }
    }

    private func totalMigrationTime() -> NSTimeInterval {
        return stopTimestamp!.timeIntervalSinceDate(startTimestamp!)
    }
}
