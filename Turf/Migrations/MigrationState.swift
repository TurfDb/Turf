public enum MigrationState {
    case Unstarted(totalRows: UInt)
    case Migrating(progress: UInt, of: UInt)
    case Completed(Result<UInt>)
}
