//
//  KeyValueSQLiteAdapter.swift
//  Turf
//
//  Created by Jordan Hamill on 21/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import SQLite

internal class KeyValueSQLiteAdapter {

    let db: SQLite.Connection

    private let queryCache: SQLStatementCache

    init(db: SQLite.Connection) {
        self.db = db
        self.queryCache = SQLStatementCache()
    }

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

    func numberOfKeysInCollectionNamed(collection: String) -> UInt {
        return 0
    }

    func keysInCollectionNamed<TPrimaryKey: AllowedPrimaryKeyType>(collection: String) -> [TPrimaryKey] {
        return []
    }

    func setValueData<TPrimaryKey: AllowedPrimaryKeyType>(value: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {

    }

    func setMetadataData<TPrimaryKey: AllowedPrimaryKeyType>(metadata: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {

    }

    func setValueData<TPrimaryKey: AllowedPrimaryKeyType>(value: NSData?, metadata: NSData?, forKey: TPrimaryKey, inCollectionNamed: String) {

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

    func removeAllRowsInCollectionNamed(collection: String) {

    }

    func removeRowWithKey<TPrimaryKey: AllowedPrimaryKeyType>(key: TPrimaryKey, inCollectionNamed: String) {
        
    }
}
