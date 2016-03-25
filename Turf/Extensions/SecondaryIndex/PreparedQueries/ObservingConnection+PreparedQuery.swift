extension ObservingConnection {
    /**
     Prepare a query for retrieving a single value from `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `ObservingConnection` they were created from.
     - parameter collection: Secondary indexed collection where a matching value will be searched for.
     - parameter valueWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, valueWhere clause: WhereClause) throws -> PreparedValueWhereQuery {
        return try connection.prepareQueryFor(collection, valueWhere: clause)
    }

    /**
     Prepare a query for retrieving values from `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `ObservingConnection` they were created from.
     - parameter collection: Secondary indexed collection where matching values will be searched for.
     - parameter valuesWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, valuesWhere clause: WhereClause) throws -> PreparedValuesWhereQuery {
        return try connection.prepareQueryFor(collection, valuesWhere: clause)
    }

    /**
     Prepare a query for retrieving a count of values matching `countWhere` in `collection`.
     Use a prepared query for performance critcal areas where a query will be executed regularly.
     - warning: Prepared queries can only be used on the `ObservingConnection` they were created from.
     - parameter collection: Secondary indexed collection where matching values will be counted.
     - parameter countWhere: Query clause.
     */
    public func prepareQueryFor<TCollection: IndexedCollection>(collection: TCollection, countWhere clause: WhereClause) throws -> PreparedCountWhereQuery {
        return try connection.prepareQueryFor(collection, countWhere: clause)
    }
}
