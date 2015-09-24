public final class ValuesSequence<Value>: SequenceType {
    // MARK: Private properties

    private let stmt: COpaquePointer
    private let valueDataColumnIndex: Int32
    private let deserializer: (NSData) -> Value?

    // MARK: Object lifecycle

    /**
     - parameter stmt: A prepared and bound query statement from sqlite3_prepare[_v2]
     - parameter valueDataColumnIndex: Column index of the value blob
     - parameter deserializer: Deserializer for `Value` which is applied to the blob at `valueDataColumnIndex`
     */
    internal init(stmt: COpaquePointer, valueDataColumnIndex: Int32, deserializer: (NSData) -> Value?) {
        self.stmt = stmt
        self.valueDataColumnIndex = valueDataColumnIndex
        self.deserializer = deserializer
    }

    deinit {
        finalize()
    }

    // MARK: Public methods

    /**
     - returns: A generator over rows of `Value`.
     */
    public func generate() -> AnyGenerator<Value> {
        return anyGenerator {
            guard sqlite3_step(self.stmt).hasRow else {
                self.finalize()
                return nil
            }

            let bytes = sqlite3_column_blob(self.stmt, self.valueDataColumnIndex)
            let bytesLength = Int(sqlite3_column_bytes(self.stmt, self.valueDataColumnIndex))
            let data = NSData(bytes: bytes, length: bytesLength)

            return self.deserializer(data)
        }
    }

    /**
     This *must* be called before ValueSequence goes out of scope.
     */
    public func finalize() {
        sqlite3_finalize(self.stmt)
    }
}
