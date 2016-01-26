public protocol SQLiteType {
    static var sqliteTypeName: SQLiteTypeName { get }
}

extension SQLiteType {
    var sqliteTypeName: SQLiteTypeName { return Self.sqliteTypeName }
}

extension Int64: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Integer
    }
}

extension Int: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Integer
    }
}

extension String: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Text
    }
}

extension Bool: SQLiteType {
    public static var sqliteTypeName: SQLiteTypeName {
        return .Integer
    }
}
