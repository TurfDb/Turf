/**
 Define a property of type `T` that will be indexed.
 */
public struct IndexedProperty<IndexedCollection: Collection, T: SQLiteType> {
    // MARK: Public properties

    public let name: String

    public let Type: T.Type = T.self

    // MARK: Internal properties

    /// Property getter
    internal var propertyValueForValue: (IndexedCollection.Value -> T)

    // MARK: Object lifecycle

    /**
     - parameter name: Property name
     - parameter propertyValueForValue: Getter for the property
     */
    public init(name: String, propertyValueForValue: (IndexedCollection.Value -> T)) {
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
    public func equals(value: T) -> WhereClause {
        return WhereClauses.equals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func doesNotEqual(value: T) -> WhereClause {
        return WhereClauses.notEquals(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isIn(values: [T]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotIn(values: [T]) -> WhereClause {
        return WhereClauses.IN(name: name, values: values, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isBetween(left: T, right: T) -> WhereClause {
        return WhereClauses.between(name: name, left: left, right: right)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThan(value: T) -> WhereClause {
        return WhereClauses.lessThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isLessThanOrEqualTo(value: T) -> WhereClause {
        return WhereClauses.lessThanOrEqual(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThan(value: T) -> WhereClause {
        return WhereClauses.greaterThan(name: name, value: value)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isGreaterThanOrEqualTo(value: T) -> WhereClause {
        return WhereClauses.greaterThanOrEqual(name: name, value: value)
    }

    public func lift() -> IndexedPropertyFromCollection<IndexedCollection> {
        return IndexedPropertyFromCollection(property: self)
    }

    // MARK: Internal methods

    internal func bindPropertyValue(value: IndexedCollection.Value, toSQLiteStmt stmt: COpaquePointer, atIndex index: Int32) -> Int32 {
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
    public func isLike(value: T) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter value
     - returns: A predicate
     */
    public func isNotLike(value: T) -> WhereClause {
        return WhereClauses.like(name: name, value: value._turfSwiftString, negate: true)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func matchesRegex(regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern)
    }

    /**
     Generates a SQL predicate
     - note: Property must be comparable within SQLite
     - parameter regex
     - returns: A predicate
     */
    public func doesNotMatcheRegex(regex: NSRegularExpression) -> WhereClause {
        return WhereClauses.regexp(name: name, regex: regex.pattern, negate: true)
    }
}

extension IndexedProperty where T: TurfSQLiteOptional {
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
}
