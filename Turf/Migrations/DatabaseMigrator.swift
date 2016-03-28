import Foundation

public class DatabaseMigrator {
    public enum Error: ErrorType {
        case MigrationsCurrentlyRunning
        case MissingMigration(missingIndex: UInt)
    }

    // MARK: Public properties

    public let migrationList: MigrationList

    public var migrationRequired: Bool {
        return migrationList.count > 0 && migrationList.lastMigrationIndex > lastRunMigrationIndex
    }

    public private(set) var lastRunMigrationIndex: UInt {
        get {
            return UInt(userDefaults.integerForKey(lastRunMigrationKey))
        }
        set {
            userDefaults.setInteger(Int(newValue), forKey: lastRunMigrationKey)
            userDefaults.synchronize()
        }
    }

    public var onNextMigration: ((index: UInt, total: UInt) -> Void)?
    public var onMigrationProgressChanged: ((index: UInt, progress: UInt, of: UInt) -> Void)?

    // MARK: Private properties

    private let userDefaults: NSUserDefaults
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

    /**
     Open a database for migration. The last run migration will be stored in `userDefaults`.
     */
    public init(databaseUrl: NSURL, migrationList: MigrationList, userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) throws {
        self.userDefaults = userDefaults
        self.migrationList = migrationList
        self.migrating = false

        self.sqlite = try SQLiteAdapter(sqliteDatabaseUrl: databaseUrl)
        self.migrationOperations = MigrationOperations(sqlite: self.sqlite)
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
            // MigrationList.migrations use 1 based indexing so this also covers the first ever migration
            try migrate(lastRunMigrationIndex + 1)
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
            lastRunMigrationIndex = index
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

private let lastRunMigrationKey = "TurfLastRunMigration"
