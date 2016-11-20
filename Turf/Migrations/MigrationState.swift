public enum MigrationState {
    case unstarted(totalRows: UInt)
    case migrating(UInt, of: UInt)
    case completed(Result<UInt>)
}
