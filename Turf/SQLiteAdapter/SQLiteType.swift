public protocol SQLiteType {
    static var sqliteTypeName: SQLiteTypeName { get }

    /**
     Extract the type from a (sqlite3_stmt *).

     - parameter stmt: sqlite3_stmt.
     - parameter columnIndex: Index of the column to be extracted.
     */
    init?(stmt: OpaquePointer, columnIndex: Int32)

    /**
     Bind the type to a sqlite3_stmt.

     - parameter stmt: sqlite3_stmt.
     - parameter index: Index of the column to bind to.
     */
    func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32

    func sqliteValue() -> SQLiteType
}

extension SQLiteType {
    public var sqliteTypeName: SQLiteTypeName { return Self.sqliteTypeName }
}

extension Int: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Integer
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        self = Int(sqlite3_column_int64(stmt, columnIndex))
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        return sqlite3_bind_int64(stmt, index, Int64(self))
    }

    public func sqliteValue() -> SQLiteType {
        return self
    }
}

extension String: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Text
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        if let text = String(validatingUTF8: sqlite3_column_text(stmt, columnIndex)!) {
            self = text
        } else {
            return nil
        }
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        return sqlite3_bind_text(stmt, index, self, -1, SQLITE_TRANSIENT)
    }

    public func sqliteValue() -> SQLiteType {
        return "`\(self)`"
    }

    public init?(validatingUTF8 cString: UnsafePointer<UInt8>) {
        guard let (s, _) = String.decodeCString(cString, as: UTF8.self,
                                                repairingInvalidCodeUnits: false) else {
                                                    return nil
        }
        self = s
    }
}

extension Bool: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Integer
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        self = sqlite3_column_int64(stmt, columnIndex) != 0
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        return sqlite3_bind_int64(stmt, index, self ? 1 : 0)
    }

    public func sqliteValue() -> SQLiteType {
        return self ? 1 : 0
    }
}

extension Double: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Real
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        self = sqlite3_column_double(stmt, columnIndex)
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        return sqlite3_bind_double(stmt, index, self)
    }

    public func sqliteValue() -> SQLiteType {
        return self
    }
}

extension Float: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Real
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        self = Float(sqlite3_column_double(stmt, columnIndex))
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        return sqlite3_bind_double(stmt, index, Double(self))
    }

    public func sqliteValue() -> SQLiteType {
        return self
    }
}

public protocol TurfSQLiteOptional {
    associatedtype _Wrapped: SQLiteType
}

public enum SQLiteOptional<Wrapped: SQLiteType>: SQLiteType, TurfSQLiteOptional {
    public typealias _Wrapped = Wrapped

    case some(Wrapped)
    case none

    public static var sqliteTypeName: SQLiteTypeName {
        return Wrapped.sqliteTypeName
    }

    public init?(stmt: OpaquePointer, columnIndex: Int32) {
        if let wrapped = Wrapped(stmt: stmt, columnIndex: columnIndex) {
            self = .some(wrapped)
        } else {
            self = .none
        }
    }

    public func sqliteBind(_ stmt: OpaquePointer, index: Int32) -> Int32 {
        switch self {
        case .some(let value):
            return value.sqliteBind(stmt, index: index)
        case .none:
            return sqlite3_bind_null(stmt, index)
        }
    }

    public func sqliteValue() -> SQLiteType {
        return self
    }
}

extension Optional where Wrapped: SQLiteType {
    public func toSQLite() -> SQLiteOptional<Wrapped> {
        switch self {
        case .some(let wrapped): return .some(wrapped)
        case .none: return .none
        }
    }
}
