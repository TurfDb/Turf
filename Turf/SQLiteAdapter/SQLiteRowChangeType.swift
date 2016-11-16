/**
 As Turf is a key value store, a setValue call can either insert of update a row.
 */
internal enum SQLiteRowChangeType {
    /// `setValue(...)` caused an insert. `rowId` is the internal sqlite3 `rowid` value.
    case insert(rowId: Int64)

    /// `setValue(...)` caused an update. `rowId` is the internal sqlite3 `rowid` value.
    case update(rowId: Int64)
}
