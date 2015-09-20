//
//  ReadTransaction.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

public struct CollectionKeyedBy<TPrimaryKey>: Collection {
    public typealias TKey = TPrimaryKey

    public let name: String
}

public class ReadTransaction {
    public private(set) unowned var connection: Connection

    internal init(connection: Connection) {
        self.connection = connection
    }

    // MARK: Count

    public func numberOfCollections() -> UInt {
        return 0
    }

    public func numberOfKeysInAllCollections() -> UInt {
        return 0
    }

    // MARK: List

    public func allCollectionNames() -> [String] {
        return []
    }

    public func primaryKeyTypes() -> [String: AllowedPrimaryKeyType] {
        return [:]
    }

    public func collections() -> [Collection] {
        return []
    }
}
