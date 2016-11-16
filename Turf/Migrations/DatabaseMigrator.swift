import Foundation

open class DatabaseMigrator {
    public enum MigrationError: Error {
        case migrationsCurrentlyRunning
        case missingMigration(missingIndex: UInt)
    }

    // MARK: Public properties

    open let migrationList: MigrationList

    open var migrationRequired: Bool {
        return migrationList.count > 0 && migrationList.lastMigrationIndex > lastRunMigrationIndex
    }

    open fileprivate(set) var lastRunMigrationIndex: UInt {
        get {
            return UInt(userDefaults.integer(forKey: lastRunMigrationKey))
        }
        set {
            userDefaults.set(Int(newValue), forKey: lastRunMigrationKey)
            userDefaults.synchronize()
        }
    }

    open var onNextMigration: ((_ index: UInt, _ total: UInt) -> Void)?
    open var onMigrationProgressChanged: ((_ index: UInt, _ progress: UInt, _ of: UInt) -> Void)?

    // MARK: Private properties

    fileprivate let userDefaults: UserDefaults
    fileprivate var sqlite: SQLiteAdapter!
    fileprivate var migrationOperations: MigrationOperations!
    fileprivate var startTimestamp: Date?
    fileprivate var stopTimestamp: Date?

    fileprivate var migrating: Bool {
        didSet {
            if !oldValue && migrating { startTimestamp = Date() }
            else if oldValue && !migrating { stopTimestamp = Date() }
        }
    }

    fileprivate var onMigrationsCompleted: ((Result<TimeInterval>) -> Void)?

    // MARK: Object lifecycle

    /**
     Open a database for migration. The last run migration will be stored in `userDefaults`.
     */
    public init(databaseUrl: URL, migrationList: MigrationList, userDefaults: UserDefaults = UserDefaults.standard) throws {
        self.userDefaults = userDefaults
        self.migrationList = migrationList
        self.migrating = false

        self.sqlite = try SQLiteAdapter(sqliteDatabaseUrl: databaseUrl)
        self.migrationOperations = MigrationOperations(sqlite: self.sqlite)
    }

    // MARK: Internal methods

    func migrate(_ onCompletion: @escaping (Result<TimeInterval>) -> Void) {
        guard !migrating else {
            onCompletion(.failure(MigrationError.migrationsCurrentlyRunning))
            return
        }

        migrating = true

        guard migrationRequired else {
            sqlite.close()
            migrating = false
            onCompletion(.success(totalMigrationTime()))
            return
        }

        onMigrationsCompleted = onCompletion

        do {
            // MigrationList.migrations use 1 based indexing so this also covers the first ever migration
            try migrate(lastRunMigrationIndex + 1)
        } catch {
            onCompletion(.failure(error))
        }
    }

    // MARK: Private methods

    fileprivate func migrate(_ index: UInt) throws {
        switch migrationForIndex(index) {
        case .success(let migration):
            try sqlite.beginDeferredTransaction()
            migration.migrate(migrationId: index, operations: migrationOperations, onProgress: migrationProgress)
            break
        case .failure(let error):
            migrationProgress(index: index, state: MigrationState.completed(.failure(error)))
        }
    }

    fileprivate func migrationProgress(index: UInt, state: MigrationState) {
        switch state {
        case .unstarted(totalRows: let total):
            onNextMigration?(index, total)
        case .migrating(let currentPosition, let total):
            onMigrationProgressChanged?(index, currentPosition, total)
        case .completed(let result):
            switch result {
            case .success(let total):
                migrationSuccess(index, totalRowsMigrated: total)
            case .failure(let error):
                migrationFailure(index, error: error as! DatabaseMigrator.MigrationError)
            }
        }
    }

    fileprivate func migrationSuccess(_ index: UInt, totalRowsMigrated: UInt) {
        do {
            try sqlite.commitTransaction()
            lastRunMigrationIndex = index
        } catch {
            migrationFailure(index, error: error as! DatabaseMigrator.MigrationError)
        }

        onMigrationProgressChanged?(index, totalRowsMigrated, totalRowsMigrated)
        guard index != self.migrationList.lastMigrationIndex else {
            sqlite.close()
            migrating = false
            onMigrationsCompleted!(.success(totalMigrationTime()))
            return
        }

        do {
            try migrate(index + 1)
        } catch {
            migrationFailure(index, error: error as! DatabaseMigrator.MigrationError)
        }
    }

    fileprivate func migrationFailure(_ index: UInt, error: MigrationError) {
        let _ = try? sqlite.rollbackTransaction()
        sqlite.close()
        onMigrationsCompleted!(.failure(error))
    }

    fileprivate func migrationForIndex(_ index: UInt) -> Result<Migration> {
        if let migration = migrationList.migrations[index] {
            return .success(migration)
        } else {
            return .failure(MigrationError.missingMigration(missingIndex: index))
        }
    }

    fileprivate func totalMigrationTime() -> TimeInterval {
        return stopTimestamp!.timeIntervalSince(startTimestamp!)
    }
}

private let lastRunMigrationKey = "TurfLastRunMigration"
