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

}

extension KeyValueSQLiteAdapter {
    // MARK: Collections queries
    func collectionNames() -> [String] {
        let q = queryCache.query(key: "col names", query: db.prepare("INSERT INTO users (email) VALUES (?)"))
        try! q.run([])
        return []
    }

    func primaryKeyTypes() -> [String: AllowedPrimaryKeyType] {
        return [:]
    }

    func numberOfCollections() -> UInt {
        return 0
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

