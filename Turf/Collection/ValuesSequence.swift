public final class ValuesSequence<Value>: Sequence {
    // MARK: Private properties

    private let stmt: OpaquePointer
    private let valueDataColumnIndex: Int32
    private let schemaVersionColumnIndex: Int32
    private let deserializer: (Data) -> Value?
    private let collectionSchemaVersion: UInt64

    // MARK: Object lifecycle

    /**
     - parameter stmt: A prepared and bound query statement from sqlite3_prepare_v2
     - parameter valueDataColumnIndex: Column index of the value blob
     - paramater schemaVersionColumnIndex: Column index of the schemaVersion
     - parameter deserializer: Deserializer for `Value` which is applied to the blob at `valueDataColumnIndex`
     */
    internal init(stmt: OpaquePointer, valueDataColumnIndex: Int32, schemaVersionColumnIndex: Int32, deserializer: @escaping (Data) -> Value?, collectionSchemaVersion: UInt64) {
        self.stmt = stmt
        self.valueDataColumnIndex = valueDataColumnIndex
        self.schemaVersionColumnIndex = schemaVersionColumnIndex
        self.deserializer = deserializer
        self.collectionSchemaVersion = collectionSchemaVersion
    }

    deinit {
        finalize()
    }

    // MARK: Public methods

    /**
     - returns: A generator over rows of `Value`.
     */
    public func makeIterator() -> AnyIterator<Value> {
        return AnyIterator {
            guard sqlite3_step(self.stmt).hasRow else {
                return nil
            }

            let data: Data
            if let bytes = sqlite3_column_blob(self.stmt, self.valueDataColumnIndex){
                let bytesLength = Int(sqlite3_column_bytes(self.stmt, self.valueDataColumnIndex))
                data = Data(bytes: bytes, count: bytesLength)
            } else {
                data = Data()
            }

            let schemaVersion = UInt64(sqlite3_column_int64(self.stmt, self.schemaVersionColumnIndex))
            precondition(schemaVersion == self.collectionSchemaVersion, "Collection requires a migration")
            return self.deserializer(data)
        }
    }

    // MARK: Private methods

    private func finalize() {
        sqlite3_reset(self.stmt)
    }
}
