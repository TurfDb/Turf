//
//  KeyValueSQLiteAdapter.swift
//  Turf
//
//  Created by Jordan Hamill on 21/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

internal class KeyValueSQLiteAdapter {
    func collectionNames() -> [String] {
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
