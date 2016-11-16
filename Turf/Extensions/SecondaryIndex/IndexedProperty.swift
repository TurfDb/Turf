/**
 Define a property of type `T` that will be indexed.
 */
public struct IndexedProperty<IndexedCollection: TurfCollection, T: SQLiteType> {
    // MARK: Public properties

    public let name: String

    public let PropertyType: T.Type = T.self

    // MARK: Internal properties

    /// Property getter
    internal var propertyValueForValue: ((IndexedCollection.Value) -> T)

    // MARK: Object lifecycle

    /**
     - parameter name: Property name
     - parameter propertyValueForValue: Getter for the property
     */
    public init(name: String, propertyValueForValue: @escaping ((IndexedCollection.Value) -> T)) {
        self.name = name
        self.propertyValueForValue = propertyValueForValue
    }

    // MARK: Public methods

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
    */
    public func equals(_ value: T) -> WhereClause {
        return WhereClauses.equals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func doesNotEqual(_ value: T) -> WhereClause {
        return WhereClauses.notEquals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isIn(_ values: [T]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotIn(_ values: [T]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isBetween(_ left: T, right: T) -> WhereClause {
        return WhereClauses.between(name: name, left: left, right: right)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThan(_ value: T) -> WhereClause {
        return WhereClauses.lessThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThanOrEqualTo(_ value: T) -> WhereClause {
        return WhereClauses.lessThanOrEqual(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThan(_ value: T) -> WhereClause {
        return WhereClauses.greaterThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThanOrEqualTo(_ value: T) -> WhereClause {
        return WhereClauses.greaterThanOrEqual(name: name, value: value)
    }

    public func lift() -> IndexedPropertyFromCollection<IndexedCollection> {
        return IndexedPropertyFromCollection(property: self)
    }

    // MARK: Internal methods

    internal func bindPropertyValue(_ value: IndexedCollection.Value, toSQLiteStmt stmt: OpaquePointer, atIndex index: Int32) -> Int32 {
        let value = propertyValueForValue(value)
        return value.sqliteBind(stmt, index: index)
    }
}

public protocol TurfSwiftString { var _turfSwiftString: String { get } }
extension String: TurfSwiftString {
    public var _turfSwiftString: String { return self }
}

extension IndexedProperty where T: TurfSwiftString {
    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLike(_ value: T) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotLike(_ value: T) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func matchesRegex(_ regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func doesNotMatcheRegex(_ regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern, negate: true)
    }
}

extension IndexedProperty where T: TurfSQLiteOptional, T._Wrapped: SQLiteType {
    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNil() -> WhereClause {
        return WhereClauses.isNull(name: name)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotNil() -> WhereClause {
        return WhereClauses.isNull(name: name, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func equals(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.equals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func doesNotEqual(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.notEquals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isIn(_ values: [T._Wrapped]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotIn(_ values: [T._Wrapped]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isBetween(_ left: T._Wrapped, right: T._Wrapped) -> WhereClause {
        return WhereClauses.between(name: name, left: left, right: right)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThan(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.lessThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThanOrEqualTo(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.lessThanOrEqual(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThan(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.greaterThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThanOrEqualTo(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.greaterThanOrEqual(name: name, value: value)
    }
}

extension IndexedProperty where T: TurfSQLiteOptional, T._Wrapped: SQLiteType, T._Wrapped: TurfSwiftString {
    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLike(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotLike(_ value: T._Wrapped) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func matchesRegex(_ regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func doesNotMatcheRegex(_ regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern, negate: true)
    }
}
