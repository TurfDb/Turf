public enum MigrationState {
    case Unstarted(totalRows: UInt)
    case Migrating(UInt, of: UInt)
    case Completed(Result<UInt>)
}
