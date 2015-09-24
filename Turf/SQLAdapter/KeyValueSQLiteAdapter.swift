//
//  KeyValueSQLiteAdapter.swift
//  Turf
//
//  Created by Jordan Hamill on 21/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import SQLite

///
/// Specific methods to handing collections and data in a KV way
///
internal class KeyValueSQLiteAdapter {

    let db: SQLite.Connection

    private let queryCache: SQLStatementCache

    init(db: SQLite.Connection) {
        self.db = db
        self.queryCache = SQLStatementCache()
    }
}

extension KeyValueSQLiteAdapter {
    // MARK: Collections creation/deletion
    func createCollectionTableNamed<T: AllowedPrimaryKeyType>(name: String, primaryKeyType: T.Type) throws -> SQLCollectionTable<T> {
        let table = SQLCollectionTable<T>(name: name)

        //TODO Check if it exists first
        if true {
            try db.run(table.T.create { t in
                t.primaryKey(table.key)
                t.column(table.data)
                t.column(table.metadata)
                })
        }

        return table
    }

    func dropCollectionTable<T: AllowedPrimaryKeyType>(table: SQLCollectionTable<T>) throws {

    }
}

extension KeyValueSQLiteAdapter {
    // MARK: Collections queries

    func numberOfCollections() -> UInt {
        //        let q = queryCache.query(key: "col names", query: db.prepare("INSERT INTO users (email) VALUES (?)"))
        return 0
    }

    func collectionNames() throws -> [String] {
        return []
    }

    func collectionPrimaryKeyTypes() -> [String: AllowedPrimaryKeyType.Type] {
        return [:]
    }
}

extension KeyValueSQLiteAdapter {
    // MARK: Collection queries

    func numberOfKeysInCollectionNamed(collection: String) -> UInt {
        return 0
    }

    func keysInCollectionNamed<TPrimaryKey: AllowedPrimaryKeyType>(collection: String) -> [TPrimaryKey] {
        return []
    }

    func valueDataForKey<TPrimaryKey: AllowedPrimaryKeyType>(key: TPrimaryKey, inCollectionNamed: String) -> NSData? {
        return nil
    }

    func metadataDataForKey<TPrimaryKey: AllowedPrimaryKeyType>(key: TPrimaryKey, inCollectionNamed: String) -> NSData? {
        return nil
    }

    func valueDataAndMetadataDataForKey<TPrimaryKey: AllowedPrimaryKeyType>(key: TPrimaryKey, inCollectionNamed: String) -> (NSData?, NSData?) {
        return (nil, nil)
    }
}

extension KeyValueSQLiteAdapter {
    // MARK: Collection setting

    func setValueData<TPrimaryKey: AllowedPrimaryKeyType>(value: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {

    }

    func setMetadataData<TPrimaryKey: AllowedPrimaryKeyType>(metadata: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {

    }

    func setValueData<TPrimaryKey: AllowedPrimaryKeyType>(value: NSData?, metadata: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {
        
    }

    func removeAllRowsInCollectionNamed(collection: String) {

    }

    func removeRowWithKey<TPrimaryKey: AllowedPrimaryKeyType>(key: TPrimaryKey, inCollectionNamed: String) {

    }
}

